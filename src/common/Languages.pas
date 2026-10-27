unit Languages;

{ Textos de la interfaz en varios idiomas. El idioma se elige al arrancar a
  partir de la configuracion regional de Windows: es-*, fr-*, it-* y de-*
  tienen su tabla; cualquier otro locale usa ingles. }

interface

uses
  Winapi.Windows, System.SysUtils;

type
  TLanguage = (lgSpanish, lgEnglish, lgFrench, lgItalian, lgGerman);

  TTextId = (
    txtAppTitle, txtSettings, txtMachineA, txtMachineB, txtSubtitle,
    txtTabBadge, txtTabBand,
    txtBadgeText, txtBadgeTextHint, txtPanelColor, txtTextColor, txtChange,
    txtSize, txtPanelOpacity, txtTextOpacity, txtCornerRadius, txtMargins,
    txtBandEnable, txtSyncColor, txtBandColor, txtBandHeight, txtBandText, txtBandTextHint,
    txtBandAlignment, txtAlignRight, txtAlignCenter, txtAlignLeft,
    txtBandNoteMonitors, txtBandNoteReapply,
    txtInstall, txtApply, txtUninstall, txtReapply, txtCloseBadge, txtClose,
    txtRepair, txtUpdate, txtReinstall,
    txtNotInstalled, txtNotInstalledHint, txtInstalledHost, txtUpdateAvailable,
    txtRepairNeeded, txtLeftoversRepair, txtStartupActive, txtStartupInactive,
    txtBadgeRunning, txtBadgeStopped,
    txtMissingStartup, txtStartupWrongPath, txtMissingIni, txtStartupMissingExe,
    txtLeftovers, txtBadgeRunningNotInstalled, txtPressRepair,
    txtUpdateAvailableMsg, txtClicksThrough, txtNotInstalledApply, txtError,
    txtInstalledApplied, txtRepairedApplied, txtReinstalledApplied,
    txtInstallApplyFailed, txtRepairApplyFailed, txtReinstallApplyFailed,
    txtApplied, txtReapplied, txtUpdatedBand, txtUpdatedNoBand, txtBandDisabled,
    txtCloseSent,
    txtUpdateDialogCaption, txtUpdateDialogTitle, txtUpdateDialogText,
    txtUninstallDialogCaption, txtUninstallDialogTitle, txtUninstallDialogText,
    txtKeepConfig,
    txtHostNotFound, txtCreateDirFailed, txtHostStillRunning, txtCopyFailed,
    txtWriteIniFailed, txtStartupRegisterFailed, txtInstalledIn,
    txtNoInstallToUpdate, txtAlreadyVersion, txtHostRunningNoUpdate,
    txtUpdatedTo, txtUpdated, txtNotInstalledPressInstall,
    txtSaveConfigFailed, txtSaveOriginalFailed, txtGenerateBandFailed,
    txtApplyWallpaperFailed, txtUninstalledKeep, txtUninstallFolderFailed,
    txtUninstalledAll,
    txtHostWindowTitle, txtHostStartError);

var
  IdiomaActual: TLanguage;

function DetectarIdioma: TLanguage;
function Texto(Id: TTextId): string;
function TextoFmt(Id: TTextId; const Args: array of const): string;
function NombreIdioma: string;

implementation

const
  TABLA: array[TTextId, TLanguage] of string = (
    // txtAppTitle
    ('DesktopIdentifier', 'DesktopIdentifier', 'DesktopIdentifier', 'DesktopIdentifier', 'DesktopIdentifier'),
    // txtSettings
    ('Configuración', 'Settings', 'Paramètres', 'Impostazioni', 'Einstellungen'),
    // txtMachineA
    ('Máquina A', 'Machine A', 'Machine A', 'Macchina A', 'Rechner A'),
    // txtMachineB
    ('Máquina B', 'Machine B', 'Machine B', 'Macchina B', 'Rechner B'),
    // txtSubtitle
    ('Marca visual para distinguir esta máquina de la otra · v%s',
     'Visual marker to tell this machine apart from the other · v%s',
     'Repère visuel pour distinguer cette machine de l’autre · v%s',
     'Contrassegno visivo per distinguere questa macchina dall’altra · v%s',
     'Visuelle Markierung, um diesen Rechner vom anderen zu unterscheiden · v%s'),
    // txtTabBadge
    ('Cartel', 'Badge', 'Badge', 'Badge', 'Kennzeichen'),
    // txtTabBand
    ('Banda', 'Band', 'Bande', 'Banda', 'Band'),
    // txtBadgeText
    ('Texto del cartel:', 'Badge text:', 'Texte du badge :', 'Testo del badge:', 'Kennzeichen-Text:'),
    // txtBadgeTextHint
    ('Sin límite', 'No limit', 'Sans limite', 'Senza limite', 'Kein Limit'),
    // txtPanelColor
    ('Color del panel:', 'Panel color:', 'Couleur du panneau :', 'Colore del pannello:', 'Panel-Farbe:'),
    // txtTextColor
    ('Color del texto:', 'Text color:', 'Couleur du texte :', 'Colore del testo:', 'Textfarbe:'),
    // txtChange
    ('Cambiar...', 'Change...', 'Modifier…', 'Cambia…', 'Ändern…'),
    // txtSize
    ('Tamaño:', 'Size:', 'Taille :', 'Dimensione:', 'Größe:'),
    // txtPanelOpacity
    ('Opacidad del panel:', 'Panel opacity:', 'Opacité du panneau :', 'Opacità del pannello:', 'Panel-Deckkraft:'),
    // txtTextOpacity
    ('Opacidad del texto:', 'Text opacity:', 'Opacité du texte :', 'Opacità del testo:', 'Text-Deckkraft:'),
    // txtCornerRadius
    ('Radio de las esquinas:', 'Corner radius:', 'Rayon des coins :', 'Raggio degli angoli:', 'Eckenradius:'),
    // txtMargins
    ('Márgenes (der./inf.):', 'Margins (right/bottom):', 'Marges (droite/bas) :', 'Margini (destra/basso):', 'Ränder (rechts/unten):'),
    // txtBandEnable
    ('Poner la banda de color en el escritorio (fondo de pantalla)',
     'Put the color band on the desktop (wallpaper)',
     'Afficher la bande de couleur sur le bureau (fond d’écran)',
     'Mostra la banda colorata sul desktop (sfondo)',
     'Farbband auf dem Desktop anzeigen (Hintergrundbild)'),
    // txtSyncColor
    ('Sincronizar el color del cartel y la banda',
     'Synchronize badge and band colors',
     'Synchroniser les couleurs du badge et de la bande',
     'Sincronizza i colori di badge e banda',
     'Farben von Kennzeichen und Band synchronisieren'),
    // txtBandColor
    ('Color de la banda:', 'Band color:', 'Couleur de la bande :', 'Colore della banda:', 'Bandfarbe:'),
    // txtBandHeight
    ('Altura de la banda:', 'Band height:', 'Hauteur de la bande :', 'Altezza della banda:', 'Bandhöhe:'),
    // txtBandText
    ('Texto de la banda:', 'Band text:', 'Texte de la bande :', 'Testo della banda:', 'Bandtext:'),
    // txtBandTextHint
    ('Vacío = sin texto', 'Empty = no text', 'Vide = sans texte', 'Vuoto = nessun testo', 'Leer = kein Text'),
    // txtBandAlignment
    ('Alineación del texto:', 'Text alignment:', 'Alignement du texte :', 'Allineamento del testo:', 'Textausrichtung:'),
    // txtAlignRight
    ('Derecha', 'Right', 'Droite', 'Destra', 'Rechts'),
    // txtAlignCenter
    ('Centro', 'Center', 'Centre', 'Centro', 'Mitte'),
    // txtAlignLeft
    ('Izquierda', 'Left', 'Gauche', 'Sinistra', 'Links'),
    // txtBandNoteMonitors
    ('La banda es parte del fondo: Windows la repite en todos los monitores.',
     'The band is part of the wallpaper: Windows repeats it on every monitor.',
     'La bande fait partie du fond d’écran : Windows la répète sur tous les écrans.',
     'La banda fa parte dello sfondo: Windows la ripete su ogni monitor.',
     'Das Band ist Teil des Hintergrundbilds: Windows wiederholt es auf allen Monitoren.'),
    // txtBandNoteReapply
    ('Si cambias el fondo a mano, pulsa «Reaplicar banda».',
     'If you change the wallpaper by hand, press “Reapply band”.',
     'Si vous changez le fond d’écran à la main, appuyez sur « Réappliquer la bande ».',
     'Se cambi lo sfondo a mano, premi «Riapplica banda».',
     'Wenn Sie das Hintergrundbild manuell ändern, drücken Sie „Band erneut anwenden“.'),
    // txtInstall
    ('Instalar', 'Install', 'Installer', 'Installa', 'Installieren'),
    // txtApply
    ('Aplicar', 'Apply', 'Appliquer', 'Applica', 'Anwenden'),
    // txtUninstall
    ('Desinstalar', 'Uninstall', 'Désinstaller', 'Disinstalla', 'Deinstallieren'),
    // txtReapply
    ('Reaplicar banda', 'Reapply band', 'Réappliquer la bande', 'Riapplica banda', 'Band erneut anwenden'),
    // txtCloseBadge
    ('Cerrar el cartel', 'Close the badge', 'Fermer le badge', 'Chiudi il badge', 'Kennzeichen schließen'),
    // txtClose
    ('Cerrar', 'Close', 'Fermer', 'Chiudi', 'Schließen'),
    // txtRepair
    ('Reparar', 'Repair', 'Réparer', 'Ripara', 'Reparieren'),
    // txtUpdate
    ('Actualizar', 'Update', 'Mettre à jour', 'Aggiorna', 'Aktualisieren'),
    // txtReinstall
    ('Reinstalar', 'Reinstall', 'Réinstaller', 'Reinstalla', 'Neu installieren'),
    // txtNotInstalled
    ('Sin instalar', 'Not installed', 'Non installé', 'Non installato', 'Nicht installiert'),
    // txtNotInstalledHint
    ('Sin instalar · pulsa Instalar para activar el cartel',
     'Not installed · press Install to activate the badge',
     'Non installé · appuyez sur Installer pour activer le badge',
     'Non installato · premi Installa per attivare il badge',
     'Nicht installiert · drücken Sie Installieren, um das Kennzeichen zu aktivieren'),
    // txtInstalledHost
    ('Instalado · host %s', 'Installed · host %s', 'Installé · hôte %s', 'Installato · host %s', 'Installiert · Host %s'),
    // txtUpdateAvailable
    ('Instalado · host %s → %s disponible',
     'Installed · host %s → %s available',
     'Installé · hôte %s → %s disponible',
     'Installato · host %s → %s disponibile',
     'Installiert · Host %s → %s verfügbar'),
    // txtRepairNeeded
    ('Instalación incompleta · pulsa Reparar',
     'Incomplete installation · press Repair',
     'Installation incomplète · appuyez sur Réparer',
     'Installazione incompleta · premi Ripara',
     'Unvollständige Installation · drücken Sie Reparieren'),
    // txtLeftoversRepair
    ('Sin instalar (hay restos) · pulsa Reparar',
     'Not installed (leftovers) · press Repair',
     'Non installé (fichiers restants) · appuyez sur Réparer',
     'Non installato (residui) · premi Ripara',
     'Nicht installiert (Reste) · drücken Sie Reparieren'),
    // txtStartupActive
    (' · arranque activo', ' · startup active', ' · démarrage actif', ' · avvio attivo', ' · Autostart aktiv'),
    // txtStartupInactive
    (' · arranque NO activo', ' · startup NOT active', ' · démarrage INACTIF', ' · avvio NON attivo', ' · Autostart NICHT aktiv'),
    // txtBadgeRunning
    (' · cartel en marcha', ' · badge running', ' · badge en cours', ' · badge in esecuzione', ' · Kennzeichen läuft'),
    // txtBadgeStopped
    (' · cartel detenido', ' · badge stopped', ' · badge arrêté', ' · badge arrestato', ' · Kennzeichen gestoppt'),
    // txtMissingStartup
    ('Falta el arranque automático.', 'The automatic startup entry is missing.',
     'L’entrée de démarrage automatique est absente.', 'Manca l’avvio automatico.', 'Der Autostart-Eintrag fehlt.'),
    // txtStartupWrongPath
    ('La entrada de arranque apunta a otra ruta.', 'The startup entry points to another path.',
     'L’entrée de démarrage pointe vers un autre chemin.', 'La voce di avvio punta a un altro percorso.',
     'Der Autostart-Eintrag verweist auf einen anderen Pfad.'),
    // txtMissingIni
    ('Falta el archivo de configuración.', 'The configuration file is missing.',
     'Le fichier de configuration est absent.', 'Manca il file di configurazione.', 'Die Konfigurationsdatei fehlt.'),
    // txtStartupMissingExe
    ('El arranque apunta a un programa que ya no existe.',
     'The startup entry points to a program that no longer exists.',
     'Le démarrage pointe vers un programme qui n’existe plus.',
     'L’avvio punta a un programma che non esiste più.',
     'Der Autostart verweist auf ein Programm, das nicht mehr existiert.'),
    // txtLeftovers
    ('Quedan restos de una instalación anterior.', 'There are leftovers from a previous installation.',
     'Il reste des fichiers d’une installation précédente.', 'Restano residui di un’installazione precedente.',
     'Es sind Reste einer früheren Installation vorhanden.'),
    // txtBadgeRunningNotInstalled
    ('Hay un cartel en marcha que no está instalado.', 'A badge is running but is not installed.',
     'Un badge est en cours mais n’est pas installé.', 'Un badge è in esecuzione ma non è installato.',
     'Ein Kennzeichen läuft, ist aber nicht installiert.'),
    // txtPressRepair
    ('Pulsa Reparar.', 'Press Repair.', 'Appuyez sur Réparer.', 'Premi Ripara.', 'Drücken Sie Reparieren.'),
    // txtUpdateAvailableMsg
    ('Hay una versión nueva del programa de inicio (%s → %s). Pulsa Actualizar.',
     'A new host version is available (%s → %s). Press Update.',
     'Une nouvelle version du programme de démarrage est disponible (%s → %s). Appuyez sur Mettre à jour.',
     'È disponibile una nuova versione del programma di avvio (%s → %s). Premi Aggiorna.',
     'Eine neue Version des Startprogramms ist verfügbar (%s → %s). Drücken Sie Aktualisieren.'),
    // txtClicksThrough
    ('El cartel no bloquea los clics: puedes pulsar y escribir a través de él.',
     'The badge does not block clicks: you can click and type through it.',
     'Le badge ne bloque pas les clics : vous pouvez cliquer et écrire à travers.',
     'Il badge non blocca i clic: puoi fare clic e scrivere attraverso.',
     'Das Kennzeichen blockiert keine Klicks: Sie können hindurchklicken und schreiben.'),
    // txtNotInstalledApply
    ('Sin instalar: pulsa Instalar antes de aplicar.',
     'Not installed: press Install before applying.',
     'Non installé : appuyez sur Installer avant d’appliquer.',
     'Non installato: premi Installa prima di applicare.',
     'Nicht installiert: Drücken Sie Installieren, bevor Sie anwenden.'),
    // txtError
    ('Error: %s', 'Error: %s', 'Erreur : %s', 'Errore: %s', 'Fehler: %s'),
    // txtInstalledApplied
    ('Instalado y aplicado a las %s.', 'Installed and applied at %s.',
     'Installé et appliqué à %s.', 'Installato e applicato alle %s.', 'Installiert und um %s angewendet.'),
    // txtRepairedApplied
    ('Reparado y aplicado a las %s.', 'Repaired and applied at %s.',
     'Réparé et appliqué à %s.', 'Riparato e applicato alle %s.', 'Repariert und um %s angewendet.'),
    // txtReinstalledApplied
    ('Reinstalado y aplicado a las %s.', 'Reinstalled and applied at %s.',
     'Réinstallé et appliqué à %s.', 'Reinstallato e applicato alle %s.', 'Neu installiert und um %s angewendet.'),
    // txtInstallApplyFailed
    ('Instalado, pero no se pudo aplicar: %s', 'Installed, but it could not be applied: %s',
     'Installé, mais impossible de l’appliquer : %s', 'Installato, ma non è stato possibile applicarlo: %s',
     'Installiert, aber die Anwendung ist fehlgeschlagen: %s'),
    // txtRepairApplyFailed
    ('Reparado, pero no se pudo aplicar: %s', 'Repaired, but it could not be applied: %s',
     'Réparé, mais impossible de l’appliquer : %s', 'Riparato, ma non è stato possibile applicarlo: %s',
     'Repariert, aber die Anwendung ist fehlgeschlagen: %s'),
    // txtReinstallApplyFailed
    ('Reinstalado, pero no se pudo aplicar: %s', 'Reinstalled, but it could not be applied: %s',
     'Réinstallé, mais impossible de l’appliquer : %s', 'Reinstallato, ma non è stato possibile applicarlo: %s',
     'Neu installiert, aber die Anwendung ist fehlgeschlagen: %s'),
    // txtApplied
    ('Aplicado a las %s.', 'Applied at %s.', 'Appliqué à %s.', 'Applicato alle %s.', 'Um %s angewendet.'),
    // txtReapplied
    ('Banda reaplicada a las %s.', 'Band reapplied at %s.', 'Bande réappliquée à %s.',
     'Banda riapplicata alle %s.', 'Band um %s erneut angewendet.'),
    // txtUpdatedBand
    ('Actualizado a %s y banda regenerada a las %s.',
     'Updated to %s and band regenerated at %s.',
     'Mis à jour vers %s et bande régénérée à %s.',
     'Aggiornato a %s e banda rigenerata alle %s.',
     'Auf %s aktualisiert und Band um %s neu erzeugt.'),
    // txtUpdatedNoBand
    ('Actualizado, pero no se pudo regenerar la banda: %s',
     'Updated, but the band could not be regenerated: %s',
     'Mis à jour, mais impossible de régénérer la bande : %s',
     'Aggiornato, ma non è stato possibile rigenerare la banda: %s',
     'Aktualisiert, aber das Band konnte nicht neu erzeugt werden: %s'),
    // txtBandDisabled
    ('La banda está desactivada: marca la casilla y pulsa Aplicar.',
     'The band is disabled: tick the box and press Apply.',
     'La bande est désactivée : cochez la case et appuyez sur Appliquer.',
     'La banda è disattivata: seleziona la casella e premi Applica.',
     'Das Band ist deaktiviert: Aktivieren Sie das Kontrollkästchen und drücken Sie Anwenden.'),
    // txtCloseSent
    ('Petición de cierre enviada al cartel.', 'Close request sent to the badge.',
     'Demande de fermeture envoyée au badge.', 'Richiesta di chiusura inviata al badge.',
     'Schließanforderung an das Kennzeichen gesendet.'),
    // txtUpdateDialogCaption
    ('Actualizar el programa de inicio', 'Update the startup program',
     'Mettre à jour le programme de démarrage', 'Aggiorna il programma di avvio',
     'Startprogramm aktualisieren'),
    // txtUpdateDialogTitle
    ('Actualizar', 'Update', 'Mettre à jour', 'Aggiorna', 'Aktualisieren'),
    // txtUpdateDialogText
    ('Se actualizará el programa de inicio de %s a %s. El cartel se cerrará y volverá a abrirse; la configuración y el arranque no cambian.',
     'The startup program will be updated from %s to %s. The badge will close and reopen; the configuration and startup entry will not change.',
     'Le programme de démarrage sera mis à jour de %s à %s. Le badge sera fermé puis rouvert ; la configuration et le démarrage ne changeront pas.',
     'Il programma di avvio verrà aggiornato da %s a %s. Il badge verrà chiuso e riaperto; la configurazione e l’avvio non cambieranno.',
     'Das Startprogramm wird von %s auf %s aktualisiert. Das Kennzeichen wird geschlossen und wieder geöffnet; Konfiguration und Autostart bleiben unverändert.'),
    // txtUninstallDialogCaption
    ('Desinstalar DesktopIdentifier', 'Uninstall DesktopIdentifier',
     'Désinstaller DesktopIdentifier', 'Disinstalla DesktopIdentifier',
     'DesktopIdentifier deinstallieren'),
    // txtUninstallDialogTitle
    ('Desinstalar', 'Uninstall', 'Désinstaller', 'Disinstalla', 'Deinstallieren'),
    // txtUninstallDialogText
    ('Se quitará el cartel, el arranque automático y la banda, y se restaurará el fondo de pantalla original.',
     'The badge, automatic startup and band will be removed, and the original wallpaper will be restored.',
     'Le badge, le démarrage automatique et la bande seront supprimés, et le fond d’écran d’origine sera restauré.',
     'Il badge, l’avvio automatico e la banda verranno rimossi e lo sfondo originale verrà ripristinato.',
     'Kennzeichen, Autostart und Band werden entfernt und das ursprüngliche Hintergrundbild wird wiederhergestellt.'),
    // txtKeepConfig
    ('Conservar la configuración', 'Keep the configuration', 'Conserver la configuration',
     'Mantieni la configurazione', 'Konfiguration behalten'),
    // txtHostNotFound
    ('No encuentro %s junto al configurador. Compila el grupo completo.',
     'Cannot find %s next to the configurator. Build the full project group.',
     'Impossible de trouver %s à côté du configurateur. Compilez le groupe de projets complet.',
     'Impossibile trovare %s accanto al configuratore. Compila l’intero gruppo di progetti.',
     '%s wurde neben dem Konfigurator nicht gefunden. Kompilieren Sie die gesamte Projektgruppe.'),
    // txtCreateDirFailed
    ('No se pudo crear la carpeta %s', 'Could not create the folder %s',
     'Impossible de créer le dossier %s', 'Impossibile creare la cartella %s',
     'Der Ordner %s konnte nicht erstellt werden'),
    // txtHostStillRunning
    ('El cartel sigue en marcha y no se puede actualizar. Cierralo e intentalo de nuevo.',
     'The badge is still running and cannot be updated. Close it and try again.',
     'Le badge est toujours en cours et ne peut pas être mis à jour. Fermez-le et réessayez.',
     'Il badge è ancora in esecuzione e non può essere aggiornato. Chiudilo e riprova.',
     'Das Kennzeichen läuft noch und kann nicht aktualisiert werden. Schließen Sie es und versuchen Sie es erneut.'),
    // txtCopyFailed
    ('No se pudo copiar el programa de inicio: %s', 'Could not copy the startup program: %s',
     'Impossible de copier le programme de démarrage : %s', 'Impossibile copiare il programma di avvio: %s',
     'Das Startprogramm konnte nicht kopiert werden: %s'),
    // txtWriteIniFailed
    ('No se pudo escribir %s', 'Could not write %s', 'Impossible d’écrire %s',
     'Impossibile scrivere %s', '%s konnte nicht geschrieben werden'),
    // txtStartupRegisterFailed
    ('Copiado, pero no se pudo registrar el arranque automatico.',
     'Copied, but the automatic startup could not be registered.',
     'Copié, mais le démarrage automatique n’a pas pu être enregistré.',
     'Copiato, ma non è stato possibile registrare l’avvio automatico.',
     'Kopiert, aber der Autostart konnte nicht registriert werden.'),
    // txtInstalledIn
    ('Instalado en %s y arranque activo.', 'Installed in %s with startup enabled.',
     'Installé dans %s avec le démarrage activé.', 'Installato in %s con avvio attivo.',
     'In %s installiert, Autostart aktiv.'),
    // txtNoInstallToUpdate
    ('No hay una instalación que actualizar. Pulsa Instalar.',
     'There is no installation to update. Press Install.',
     'Il n’y a aucune installation à mettre à jour. Appuyez sur Installer.',
     'Non c’è un’installazione da aggiornare. Premi Installa.',
     'Es gibt keine Installation zum Aktualisieren. Drücken Sie Installieren.'),
    // txtAlreadyVersion
    ('El programa de inicio ya está en la versión %s.', 'The startup program is already version %s.',
     'Le programme de démarrage est déjà en version %s.', 'Il programma di avvio è già alla versione %s.',
     'Das Startprogramm hat bereits Version %s.'),
    // txtHostRunningNoUpdate
    ('El cartel sigue en marcha y no se puede actualizar.',
     'The badge is still running and cannot be updated.',
     'Le badge est toujours en cours et ne peut pas être mis à jour.',
     'Il badge è ancora in esecuzione e non può essere aggiornato.',
     'Das Kennzeichen läuft noch und kann nicht aktualisiert werden.'),
    // txtUpdatedTo
    ('Programa de inicio actualizado a %s.', 'Startup program updated to %s.',
     'Programme de démarrage mis à jour vers %s.', 'Programma di avvio aggiornato a %s.',
     'Startprogramm auf %s aktualisiert.'),
    // txtUpdated
    ('Programa de inicio actualizado.', 'Startup program updated.',
     'Programme de démarrage mis à jour.', 'Programma di avvio aggiornato.',
     'Startprogramm aktualisiert.'),
    // txtNotInstalledPressInstall
    ('El programa de inicio no esta instalado. Pulsa Instalar.',
     'The startup program is not installed. Press Install.',
     'Le programme de démarrage n’est pas installé. Appuyez sur Installer.',
     'Il programma di avvio non è installato. Premi Installa.',
     'Das Startprogramm ist nicht installiert. Drücken Sie Installieren.'),
    // txtSaveConfigFailed
    ('No se pudo guardar la configuracion en %s', 'Could not save the configuration to %s',
     'Impossible d’enregistrer la configuration dans %s', 'Impossibile salvare la configurazione in %s',
     'Die Konfiguration konnte nicht in %s gespeichert werden'),
    // txtSaveOriginalFailed
    ('No se pudo guardar una copia del fondo original.', 'Could not save a copy of the original wallpaper.',
     'Impossible d’enregistrer une copie du fond d’écran d’origine.',
     'Impossibile salvare una copia dello sfondo originale.',
     'Eine Kopie des ursprünglichen Hintergrundbilds konnte nicht gespeichert werden.'),
    // txtGenerateBandFailed
    ('No se pudo generar la imagen de la banda.', 'Could not generate the band image.',
     'Impossible de générer l’image de la bande.', 'Impossibile generare l’immagine della banda.',
     'Das Bandbild konnte nicht erzeugt werden.'),
    // txtApplyWallpaperFailed
    ('No se pudo aplicar el fondo de pantalla.', 'Could not apply the wallpaper.',
     'Impossible d’appliquer le fond d’écran.', 'Impossibile applicare lo sfondo.',
     'Das Hintergrundbild konnte nicht angewendet werden.'),
    // txtUninstalledKeep
    ('Desinstalado. Se conserva la configuracion en %s', 'Uninstalled. The configuration is kept in %s',
     'Désinstallé. La configuration est conservée dans %s', 'Disinstallato. La configurazione è conservata in %s',
     'Deinstalliert. Die Konfiguration bleibt in %s erhalten'),
    // txtUninstallFolderFailed
    ('Desinstalado, pero la carpeta no se pudo borrar (puede estar en uso).',
     'Uninstalled, but the folder could not be removed (it may be in use).',
     'Désinstallé, mais le dossier n’a pas pu être supprimé (il est peut-être utilisé).',
     'Disinstallato, ma non è stato possibile rimuovere la cartella (potrebbe essere in uso).',
     'Deinstalliert, aber der Ordner konnte nicht entfernt werden (er wird möglicherweise verwendet).'),
    // txtUninstalledAll
    ('Desinstalado por completo. Fondo original restaurado.',
     'Uninstalled completely. Original wallpaper restored.',
     'Désinstallé complètement. Fond d’écran d’origine restauré.',
     'Disinstallato completamente. Sfondo originale ripristinato.',
     'Vollständig deinstalliert. Ursprüngliches Hintergrundbild wiederhergestellt.'),
    // txtHostWindowTitle
    ('DesktopIdentifier — Cartel', 'DesktopIdentifier — Badge', 'DesktopIdentifier — Badge',
     'DesktopIdentifier — Badge', 'DesktopIdentifier — Kennzeichen'),
    // txtHostStartError
    ('No se pudo iniciar el cartel.', 'The badge could not be started.',
     'Impossible de démarrer le badge.', 'Impossibile avviare il badge.',
     'Das Kennzeichen konnte nicht gestartet werden.')
  );

function IdiomaDePrefijo(const Locale: string): TLanguage;
var
  P: string;
begin
  P := LowerCase(Locale);
  if (Copy(P, 1, 3) = 'es-') or (Copy(P, 1, 3) = 'es_') then
    Result := lgSpanish
  else if (Copy(P, 1, 3) = 'fr-') or (Copy(P, 1, 3) = 'fr_') then
    Result := lgFrench
  else if (Copy(P, 1, 3) = 'it-') or (Copy(P, 1, 3) = 'it_') then
    Result := lgItalian
  else if (Copy(P, 1, 3) = 'de-') or (Copy(P, 1, 3) = 'de_') then
    Result := lgGerman
  else
    Result := lgEnglish;
end;

function DetectarIdioma: TLanguage;
var
  Buf: array[0..LOCALE_NAME_MAX_LENGTH - 1] of Char;
  Locale: string;
  LangID: Word;
begin
  Buf[0] := #0;
  if GetUserDefaultLocaleName(Buf, Length(Buf)) > 0 then
  begin
    Locale := string(PChar(@Buf[0]));
    Result := IdiomaDePrefijo(Locale);
    Exit;
  end;

  LangID := GetUserDefaultUILanguage;
  case PRIMARYLANGID(LangID) of
    LANG_SPANISH: Result := lgSpanish;
    LANG_FRENCH: Result := lgFrench;
    LANG_ITALIAN: Result := lgItalian;
    LANG_GERMAN: Result := lgGerman;
  else
    Result := lgEnglish;
  end;
end;

function Texto(Id: TTextId): string;
begin
  Result := TABLA[Id, IdiomaActual];
end;

function TextoFmt(Id: TTextId; const Args: array of const): string;
begin
  Result := Format(TABLA[Id, IdiomaActual], Args);
end;

function NombreIdioma: string;
begin
  case IdiomaActual of
    lgSpanish: Result := 'es';
    lgFrench: Result := 'fr';
    lgItalian: Result := 'it';
    lgGerman: Result := 'de';
  else
    Result := 'en';
  end;
end;

initialization
  IdiomaActual := DetectarIdioma;

end.
