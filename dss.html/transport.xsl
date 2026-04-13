<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" encoding="UTF-8" indent="yes"/>
    <xsl:key name="stations" match="station" use="@id"/>
    
    <xsl:template match="/">
        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html lang="fr">
            <head>
                <meta charset="UTF-8"/>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                <title>Train Trips Report</title>
                
                <style>
                    * {
                        margin: 0;
                        padding: 0;
                        box-sizing: border-box;
                    }
                    
                    body {
                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        margin: 0;
                        padding: 20px;
                        min-height: 100vh;
                    }
                    
                    .container {
                        max-width: 1200px;
                        margin: 0 auto;
                        background: white;
                        border-radius: 20px;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                        overflow: hidden;
                        padding: 30px;
                    }
                    
                    h1 {
                        text-align: center;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        -webkit-background-clip: text;
                        -webkit-text-fill-color: transparent;
                        background-clip: text;
                        font-size: 2.5em;
                        margin-bottom: 30px;
                        padding-bottom: 20px;
                        border-bottom: 3px solid #667eea;
                    }
                    
                    h2 {
                        color: #2c3e50;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        padding: 15px 20px;
                        border-radius: 10px;
                        margin-top: 30px;
                        margin-bottom: 20px;
                        color: white;
                        font-size: 1.5em;
                        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                    }
                    
                    h3 {
                        color: #764ba2;
                        margin-top: 25px;
                        margin-bottom: 15px;
                        padding-left: 15px;
                        border-left: 4px solid #667eea;
                        font-size: 1.3em;
                    }
                    
                    table {
                        width: 100%;
                        border-collapse: separate;
                        border-spacing: 0;
                        margin-bottom: 30px;
                        background: white;
                        border-radius: 10px;
                        overflow: hidden;
                        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                    }
                    
                    th {
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        padding: 12px 15px;
                        font-weight: 600;
                        text-transform: uppercase;
                        letter-spacing: 1px;
                        font-size: 0.9em;
                    }
                    
                    td {
                        padding: 12px 15px;
                        text-align: center;
                        border-bottom: 1px solid #e0e0e0;
                        transition: all 0.3s ease;
                    }
                    tr:last-child td {
                        border-bottom: none;
                    }
                    
                    tr:hover td {
                        background-color: #f3e5f5;
                        transform: scale(1.01);
                    }
                    
                    /* Badge styles */
                    .train-type {
                        display: inline-block;
                        padding: 4px 12px;
                        border-radius: 20px;
                        font-size: 0.85em;
                        font-weight: bold;
                    }
                    
                    .class-badge {
                        display: inline-block;
                        padding: 4px 12px;
                        border-radius: 20px;
                        font-size: 0.85em;
                        font-weight: bold;
                    }
                    
                    .price {
                        color: #27ae60;
                        font-weight: bold;
                        font-size: 1.1em;
                    }
                    
                    @keyframes fadeIn {
                        from {
                            opacity: 0;
                            transform: translateY(20px);
                        }
                        to {
                            opacity: 1;
                            transform: translateY(0);
                        }
                    }
                    
                    .container {
                        animation: fadeIn 0.6s ease-out;
                    }

                    .days {
                        color: #666;
                        font-size: 0.9em;
                        background: #f0f0f0;
                        padding: 5px 10px;
                        border-radius: 5px;
                        display: inline-block;
                    }

                    .trip-details {
                        background: #f8f9fa;
                        padding: 15px;
                        border-radius: 8px;
                        margin-bottom: 20px;
                    }

                    /* Styles de la barre de recherche */
                    .search-panel {
                        background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                        border-left: 5px solid #667eea;
                        padding: 25px;
                        border-radius: 10px;
                        margin-bottom: 30px;
                        box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                    }

                    .search-panel h2 {
                        color: #667eea;
                        margin-top: 0;
                        margin-bottom: 20px;
                        font-size: 1.3em;
                        border: none;
                        background: none;
                        padding: 0;
                        box-shadow: none;
                    }

                    .search-grid {
                        display: grid;
                        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
                        gap: 15px;
                        margin-bottom: 20px;
                    }

                    .search-group {
                        display: flex;
                        flex-direction: column;
                    }

                    .search-group label {
                        font-weight: 600;
                        color: #333;
                        margin-bottom: 6px;
                        font-size: 0.9em;
                    }

                    .search-group input,
                    .search-group select {
                        padding: 10px 12px;
                        border: 2px solid #ddd;
                        border-radius: 6px;
                        font-size: 0.95em;
                        font-family: inherit;
                        transition: border-color 0.3s ease;
                    }

                    .search-group input:focus,
                    .search-group select:focus {
                        outline: none;
                        border-color: #667eea;
                        box-shadow: 0 0 0 2px rgba(102, 126, 234, 0.1);
                    }

                    .search-buttons {
                        display: flex;
                        gap: 12px;
                        justify-content: flex-end;
                        grid-column: 1 / -1;
                        flex-wrap: wrap;
                    }

                    .btn-search {
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        padding: 10px 25px;
                        border: none;
                        border-radius: 6px;
                        font-weight: 600;
                        cursor: pointer;
                        transition: all 0.3s ease;
                        font-size: 0.95em;
                    }

                    .btn-search:hover {
                        transform: translateY(-2px);
                        box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
                    }

                    .btn-reset {
                        background: #e0e0e0;
                        color: #333;
                        padding: 10px 25px;
                        border: none;
                        border-radius: 6px;
                        font-weight: 600;
                        cursor: pointer;
                        transition: all 0.3s ease;
                        font-size: 0.95em;
                    }

                    .btn-reset:hover {
                        background: #d0d0d0;
                    }

                    .no-results {
                        text-align: center;
                        padding: 40px 20px;
                        background: #fff3cd;
                        border-radius: 8px;
                        color: #856404;
                        margin: 20px 0;
                        border-left: 4px solid #ffc107;
                    }

                    .results-section {
                        margin-top: 30px;
                    }

                    .results-section h2 {
                        color: white;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    }
                </style>
                
            </head>
            
            <body>
                <div class="container">
                    <h1>🚆 Train Trips Report</h1>
                    
                    <!-- Barre de Recherche -->
                    <div class="search-panel">
                        <h2>🔍 Filtres de Recherche</h2>
                        <form method="GET" action="/">
                            <div class="search-grid">
                                <!-- Recherche par code -->
                                <div class="search-group">
                                    <label for="code">🎫 Code du trajet</label>
                                    <input type="text" id="code" name="code" placeholder="Ex: T101, T102..." 
                                           value="{/transport/@search_code}" />
                                </div>

                                <!-- Filtre par ville de départ -->
                                <div class="search-group">
                                    <label for="departure">🏁 Ville de départ</label>
                                    <select id="departure" name="departure">
                                        <option value="">-- Toutes les villes --</option>
                                        <xsl:for-each select="/transport/stations/station">
                                            <xsl:variable name="station_name" select="@name"/>
                                            <option value="{$station_name}">
                                                <xsl:if test="$station_name = /transport/@search_departure">
                                                    <xsl:attribute name="selected">selected</xsl:attribute>
                                                </xsl:if>
                                                <xsl:value-of select="$station_name"/>
                                            </option>
                                        </xsl:for-each>
                                    </select>
                                </div>

                                <!-- Filtre par ville d'arrivée -->
                                <div class="search-group">
                                    <label for="arrival">🎯 Ville d'arrivée</label>
                                    <select id="arrival" name="arrival">
                                        <option value="">-- Toutes les villes --</option>
                                        <xsl:for-each select="/transport/stations/station">
                                            <xsl:variable name="station_name" select="@name"/>
                                            <option value="{$station_name}">
                                                <xsl:if test="$station_name = /transport/@search_arrival">
                                                    <xsl:attribute name="selected">selected</xsl:attribute>
                                                </xsl:if>
                                                <xsl:value-of select="$station_name"/>
                                            </option>
                                        </xsl:for-each>
                                    </select>
                                </div>

                                <!-- Filtre par type de train -->
                                <div class="search-group">
                                    <label for="type">🚂 Type de train</label>
                                    <select id="type" name="type">
                                        <option value="">-- Tous les types --</option>
                                        <option value="Normal">
                                            <xsl:if test="/transport/@search_type = 'Normal'">
                                                <xsl:attribute name="selected">selected</xsl:attribute>
                                            </xsl:if>
                                            Normal
                                        </option>
                                        <option value="Rapid">
                                            <xsl:if test="/transport/@search_type = 'Rapid'">
                                                <xsl:attribute name="selected">selected</xsl:attribute>
                                            </xsl:if>
                                            Rapid
                                        </option>
                                        <option value="Coradia">
                                            <xsl:if test="/transport/@search_type = 'Coradia'">
                                                <xsl:attribute name="selected">selected</xsl:attribute>
                                            </xsl:if>
                                            Coradia
                                        </option>
                                        <option value="Express">
                                            <xsl:if test="/transport/@search_type = 'Express'">
                                                <xsl:attribute name="selected">selected</xsl:attribute>
                                            </xsl:if>
                                            Express
                                        </option>
                                    </select>
                                </div>

                                <!-- Filtre par prix maximum -->
                                <div class="search-group">
                                    <label for="max_price">💰 Prix maximum (DA)</label>
                                    <input type="number" id="max_price" name="max_price" placeholder="Ex: 2000" min="0" 
                                           value="{/transport/@search_max_price}" />
                                </div>

                                <!-- Boutons -->
                                <div class="search-buttons">
                                    <button type="submit" class="btn-search">🔎 Rechercher</button>
                                    <button type="reset" class="btn-reset" onclick="window.location='/'">🔄 Réinitialiser</button>
                                </div>
                            </div>
                        </form>
                    </div>

                    <!-- Affichage des résultats -->
                    <div class="results-section">
                        <h2>📋 Résultats (<xsl:value-of select="/transport/@result_count"/> trajet(s) trouvé(s))</h2>
                        
                        <xsl:choose>
                            <xsl:when test="/transport/lines/line">
                                <!-- Résultats trouvés - les trajets s'affichent ci-dessous -->
                            </xsl:when>
                            <xsl:otherwise>
                                <div class="no-results">
                                    <p><strong>Aucun trajet ne correspond à vos critères de recherche.</strong></p>
                                    <p>Veuillez modifier vos filtres et réessayer.</p>
                                </div>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                    
                    <xsl:for-each select="/transport/lines/line">
                        
                        <h2>
                            🚉 Line <xsl:value-of select="@code"/>
                            <span style="font-size: 0.8em; margin-left: 10px;">
                                (<xsl:value-of select="key('stations', @departure)/@name"/>
                                →
                                <xsl:value-of select="key('stations', @arrival)/@name"/>)
                            </span>
                        </h2>
                        
                        <xsl:for-each select="trips/trip">
                            
                            <div class="trip-details">
                                <h3>
                                    🎫 Trip No: <xsl:value-of select="@code"/>
                                </h3>
                                
                                <table>
                                    <thead>
                                        <tr>
                                            <th>Schedule</th>
                                            <th>Train Type</th>
                                            <th>Class</th>
                                            <th>Price (DA)</th>
                                            <th>Days</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each select="class">
                                            <tr>
                                                <td>
                                                    <strong>
                                                        <xsl:value-of select="../schedule/@departure"/>
                                                    </strong> → 
                                                    <strong>
                                                        <xsl:value-of select="../schedule/@arrival"/>
                                                    </strong>
                                                </td>
                                                
                                                <td>
                                                    <span class="train-type" style="background: linear-gradient(135deg, #667eea20, #764ba220); color: #764ba2;">
                                                        🚂 <xsl:value-of select="../@type"/>
                                                    </span>
                                                </td>
                                                
                                                <td>
                                                    <span class="class-badge" style="background: #667eea20; color: #667eea;">
                                                        <xsl:value-of select="@type"/>
                                                    </span>
                                                </td>
                                                
                                                <td class="price">
                                                    💰 <xsl:value-of select="@price"/> DA
                                                </td>

                                                <td>
                                                    <span class="days">
                                                        <xsl:value-of select="../days"/>
                                                    </span>
                                                </td>
                                            </tr>
                                        </xsl:for-each>
                                    </tbody>
                                </table>
                            </div>
                            
                        </xsl:for-each>
                        
                    </xsl:for-each>

                    <footer style="text-align: center; margin-top: 40px; padding-top: 20px; border-top: 2px solid #ddd; color: #999; font-size: 0.9em;">
                        <p>🚄 Rapport de gestion des trajets ferroviaires</p>
                    </footer>
                </div>
            </body>
        </html>
    </xsl:template>
    
</xsl:stylesheet>