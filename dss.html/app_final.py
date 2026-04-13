from flask import Flask, request
import xml.etree.ElementTree as ET
import lxml.etree as etree

app = Flask(__name__)

if __name__ == '__main__':
    # ==================== ÉTAPE 1: CHARGER LE FICHIER XML ====================
    print("[*] Chargement du fichier XML...")
    try:
        tree = ET.parse('transport.xml')
        root = tree.getroot()
        print("[OK] Fichier XML chargé avec succès\n")
    except Exception as e:
        print(f"[ERREUR] Impossible de charger le XML: {e}")
        exit(1)

    # ==================== ÉTAPE 2: EXTRAIRE LES DONNÉES ====================
    print("[*] Extraction des données...")
    
    station_map = {}
    for station in root.findall('.//station'):
        station_id = station.get('id')
        station_name = station.get('name')
        station_map[station_id] = station_name
    
    all_trips = []
    for line in root.findall('.//line'):
        line_code = line.get('code')
        departure_id = line.get('departure')
        arrival_id = line.get('arrival')
        departure_name = station_map.get(departure_id, departure_id)
        arrival_name = station_map.get(arrival_id, arrival_id)
        
        for trip in line.findall('.//trip'):
            trip_code = trip.get('code')
            trip_type = trip.get('type')
            
            schedule = trip.find('schedule')
            departure_time = schedule.get('departure') if schedule is not None else 'N/A'
            arrival_time = schedule.get('arrival') if schedule is not None else 'N/A'
            
            classes_list = []
            prices = []
            for cls in trip.findall('class'):
                class_type = cls.get('type')
                class_price = int(cls.get('price', 0))
                classes_list.append({
                    'type': class_type,
                    'price': class_price
                })
                prices.append(class_price)
            
            days_elem = trip.find('days')
            days = days_elem.text if days_elem is not None else 'N/A'
            
            trip_obj = {
                'code': trip_code,
                'type': trip_type,
                'line': line_code,
                'departure_id': departure_id,
                'departure': departure_name,
                'arrival_id': arrival_id,
                'arrival': arrival_name,
                'departure_time': departure_time,
                'arrival_time': arrival_time,
                'classes': classes_list,
                'days': days,
                'min_price': min(prices) if prices else 0,
                'max_price': max(prices) if prices else 0
            }
            all_trips.append(trip_obj)
    
    print(f"[OK] {len(all_trips)} trajets extraits\n")

    # ==================== ÉTAPE 3: FONCTION DE FILTRAGE ====================
    print("[*] Création des fonctions de filtrage côté serveur...\n")
    
    def filter_trips(trips, code=None, departure=None, arrival=None, train_type=None, max_price=None):
        """Filtre les trajets selon les critères fournis"""
        filtered = trips.copy()
        
        if code and code.strip():
            code_clean = code.strip()
            filtered = [t for t in filtered if t['code'] == code_clean]
            print(f"[FILTRE] Filtre par code '{code_clean}' → {len(filtered)} trajet(s)")
        
        if departure and departure.strip():
            departure_clean = departure.strip()
            filtered = [t for t in filtered if t['departure'] == departure_clean]
            print(f"[FILTRE] Filtre par départ '{departure_clean}' → {len(filtered)} trajet(s)")
        
        if arrival and arrival.strip():
            arrival_clean = arrival.strip()
            filtered = [t for t in filtered if t['arrival'] == arrival_clean]
            print(f"[FILTRE] Filtre par arrivée '{arrival_clean}' → {len(filtered)} trajet(s)")
        
        if train_type and train_type.strip():
            train_type_clean = train_type.strip()
            filtered = [t for t in filtered if t['type'] == train_type_clean]
            print(f"[FILTRE] Filtre par type '{train_type_clean}' → {len(filtered)} trajet(s)")
        
        if max_price and max_price.strip():
            try:
                max_p = int(max_price)
                filtered = [t for t in filtered if t['min_price'] <= max_p]
                print(f"[FILTRE] Filtre par prix max {max_p} DA → {len(filtered)} trajet(s)")
            except ValueError:
                print(f"[AVERTISSEMENT] Prix invalide: {max_price}")
        
        return filtered

    # ==================== ÉTAPE 4: FONCTION DE TRANSFORMATION XML+XSL ====================
    
    def create_filtered_xml(filtered_trips, code='', departure='', arrival='', train_type='', max_price=''):
        """Crée un XML avec les trajets filtrés et les paramètres de recherche"""
        transport = ET.Element('transport', {
            'search_code': code,
            'search_departure': departure,
            'search_arrival': arrival,
            'search_type': train_type,
            'search_max_price': max_price,
            'result_count': str(len(filtered_trips))
        })
        
        stations = ET.SubElement(transport, 'stations')
        for station_id, station_name in station_map.items():
            ET.SubElement(stations, 'station', {'id': station_id, 'name': station_name})
        
        lines = ET.SubElement(transport, 'lines')
        
        lines_dict = {}
        for trip in filtered_trips:
            line_code = trip['line']
            if line_code not in lines_dict:
                lines_dict[line_code] = {
                    'code': line_code,
                    'departure': trip['departure_id'],
                    'arrival': trip['arrival_id'],
                    'trips': []
                }
            lines_dict[line_code]['trips'].append(trip)
        
        for line_code, line_data in lines_dict.items():
            line_elem = ET.SubElement(lines, 'line', 
                                     {'code': line_code,
                                      'departure': line_data['departure'],
                                      'arrival': line_data['arrival']})
            
            trips_elem = ET.SubElement(line_elem, 'trips')
            
            for trip in line_data['trips']:
                trip_elem = ET.SubElement(trips_elem, 'trip', 
                                         {'code': trip['code'],
                                          'type': trip['type']})
                
                ET.SubElement(trip_elem, 'schedule', 
                            {'departure': trip['departure_time'],
                             'arrival': trip['arrival_time']})
                
                for cls in trip['classes']:
                    ET.SubElement(trip_elem, 'class',
                                {'type': cls['type'],
                                 'price': str(cls['price'])})
                
                ET.SubElement(trip_elem, 'days').text = trip['days']
        
        return transport

    def transform_xml_with_xsl(xml_element):
        """Transforme le XML avec le XSL en HTML"""
        try:
            xml_string = ET.tostring(xml_element, encoding='unicode')
            xml_doc = etree.fromstring(xml_string.encode('utf-8'))
            xsl_doc = etree.parse('transport.xsl')
            xslt = etree.XSLT(xsl_doc)
            html_result = xslt(xml_doc)
            return str(html_result)
        except Exception as e:
            print(f"[ERREUR XSLT] {str(e)}")
            return f"<h1>Erreur de transformation: {str(e)}</h1>"

    # ==================== ÉTAPE 5: ROUTE FLASK ====================
    
    @app.route('/')
    def index():
        """Route principale - affiche la page avec recherche et résultats"""
        code = request.args.get('code', '').strip()
        departure = request.args.get('departure', '').strip()
        arrival = request.args.get('arrival', '').strip()
        train_type = request.args.get('type', '').strip()
        max_price = request.args.get('max_price', '').strip()
        
        print(f"\n{'='*50}")
        print(f"[REQUÊTE] Recherche: code='{code}', départ='{departure}', arrivée='{arrival}', type='{train_type}', prix max='{max_price}'")
        
        if not any([code, departure, arrival, train_type, max_price]):
            print("[INFO] Aucun filtre - Affichage de tous les trajets")
            filtered_trips = all_trips.copy()
        else:
            filtered_trips = filter_trips(
                all_trips,
                code=code if code else None,
                departure=departure if departure else None,
                arrival=arrival if arrival else None,
                train_type=train_type if train_type else None,
                max_price=max_price if max_price else None
            )
        
        print(f"[RÉSULTAT] {len(filtered_trips)} trajet(s) trouvé(s)\n{'='*50}\n")
        
        filtered_xml = create_filtered_xml(filtered_trips, code, departure, arrival, train_type, max_price)
        html_output = transform_xml_with_xsl(filtered_xml)
        
        return html_output, 200, {'Content-Type': 'text/html; charset=utf-8'}

    @app.route('/api/search')
    def api_search():
        """API JSON pour la recherche"""
        code = request.args.get('code', '')
        departure = request.args.get('departure', '')
        arrival = request.args.get('arrival', '')
        train_type = request.args.get('type', '')
        max_price = request.args.get('max_price', '')
        
        filtered_trips = filter_trips(
            all_trips,
            code=code if code else None,
            departure=departure if departure else None,
            arrival=arrival if arrival else None,
            train_type=train_type if train_type else None,
            max_price=max_price if max_price else None
        )
        
        return {
            'count': len(filtered_trips),
            'trips': filtered_trips
        }

    # ==================== ÉTAPE 6: AFFICHAGE DES STATISTIQUES ====================
    
    print("[*] Statistiques générales:")
    print(f"    - Nombre de stations: {len(station_map)}")
    print(f"    - Nombre total de trajets: {len(all_trips)}")
    print(f"    - Types de trains: {', '.join(sorted(set([t['type'] for t in all_trips])))}")
    print(f"    - Prix min: {min([t['min_price'] for t in all_trips])} DA")
    print(f"    - Prix max: {max([t['max_price'] for t in all_trips])} DA\n")
    
    # ==================== ÉTAPE 7: LANCEMENT DU SERVEUR ====================
    print("[*] Démarrage du serveur Flask...")
    print("[*] URL: http://127.0.0.1:5000")
    print("[*] API: http://127.0.0.1:5000/api/search?type=Rapid")
    print("[*] Appuyez sur Ctrl+C pour arrêter\n")
    
    app.run(debug=True, host='127.0.0.1', port=5000)