REM TODO SCRIPT UPGRADE IDEAS
REM HOLD-1-computer reboot weekly
REM DONE-2-popup alert when filebot fails
REM DONE-3-higher quality handbrake profile when 1080p indicated
REM DONE-4-filter for low quality movies and route to low quality directory
REM DONE-5-setup enable/disable features using global variables with true/false options
REM 6-automatically delete .torrent+data for public tracker torrents

@ECHO OFF
setlocal EnableDelayedExpansion

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Enable/Disable features of this script
SET "pauseatend=false" & REM (true=pause at the end of the script, default=false) pause the script at the very end to prevent the window from closing
SET "lowqualitycheck=true" & REM (true=seperate low quality copies, default=true) prevent the sorting of low quality movie files into a low quality destination directory
SET "unrarfiles=true" & REM (true=attempt to unrar, default=true) auto extract approved file types from .rar files
SET "rescanplex=true" & REM (true=restart/requeue Plex, default=true) requeue Plex libraries or reboot Plex server if earlier in the day than configured cutoff

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Set appropriate GLOBAL variables, including muliple sourcedir (Source Directory) locations
SET "sourcedir[1]=W:\_complete_downloads\default"
REM SET "sourcedir[2]=X:\sb-avc"
SET "movieoutputdir=\\SBHOME_NAS\DLNA\Videos\Movies\00003 - Auto-Converted"
SET "lowqualitymovieoutputdir=\\SBHOME_NAS\DLNA\Videos\Movies\00003 - Auto-Converted\Low Quality"
SET "tvoutputdir=\\SBHOME_NAS\DLNA\Videos\Television Series\00003 - Auto-Converted"
CALL SET rootdir=%sourcedir[1]%
CALL SET outputdir=%movieoutputdir%
SET "workingdir=%HOMEPATH%\temp-video_auto-converson"
SET "destdir=%workingdir%\unconverted"
SET "convdir=%workingdir%\converted"
SET "extractdir=%workingdir%\extracted"
SET /a "logretentiondays=30"
SET "logdir=\\SBHOME_NAS\Resources\Scripts"
SET "historylog=%logdir%\vac_history.log"
SET "filelog=%logdir%\vac_processed_files.log"
SET "alertfile=%logdir%\alertpopup.txt"
SET "minsizelimitbytes=51200000"
SET "tvmaxsizelimitbytes=614400000"
SET "moviemaxsizelimitbytes=2097152000"
SET "finalext=.mp4"
SET "handbrakedir=C:\Program Files\Handbrake"
SET "filebotdir=C:\Program Files\FileBot"
SET "unrardir=C:\Program Files\WinRAR"
SET "keywordtext=sample"
SET "lowqualitytext="\.CAM\.", "\-CAM\-", "\ CAM\ ", "HDTS", "HD\-TS", "CAMRip""
SET "hdtext=1080p, BRRip, BDRip, BluRay"
SET "tvhandbrakeprofile=23"
SET "hdhandbrakeprofile=23"
SET "sdhandbrakeprofile=20"
SET "tvhandbrakeprofiledisp=TV Video - AVC_TV"
SET "hdhandbrakeprofiledisp=HD Video - AVC_HD"
SET "sdhandbrakeprofiledisp=SD Video - AVC_SD"
SET "loopcount=1"
SET "mediaplayerscan=false"
SET "tvmediaplayerscan=false"
SET "moviemediaplayerscan=false"
SET "showalert=false"
SET "acceptext=.mp4, .mkv, .avi, .wmv, .m4v"
SET "autoloaddir=W:\_auto_load"
SET "torfiledir=X:\sb-avc\_torrent_files"
SET "skipdirectories=_active, _torrent_files, _auto_load, _config, _misc_downloads"
SET "tvdirectories=_television_video"
SET "plexurl=http://127.0.0.1:32400"
SET /a "friendlysize=0"
SET /a "rebootcutoffhour=8" & REM The script will not reboot the Plex Media Server from this hour forward, which is in 24hr format.

ECHO AVC SCRIPT ERROR's: > "%alertfile%"
ECHO. >> "%alertfile%"

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Display Banner
ECHO ##############################################################################################################
ECHO ##### This auto-conversion script is NOT to be used to convert any illegaly obtained, copyright material #####
ECHO ##############################################################################################################
ECHO ###                                                                                                        ###
ECHO ###                                                                                                        ###
ECHO ###         ########     #########                 ###             ###      #####             ########     ###
ECHO ###       ##########     ##########                ###             ###     ### ###           #########     ###
ECHO ###      ###             ###     ###                ###           ###     ###   ###          ###           ###
ECHO ###     ###              ###     ###                ###           ###     ###   ###         ###            ###
ECHO ###      ###             ###     ###                 ###         ###     ###     ###       ###             ###
ECHO ###       ####           ###    ###                  ###         ###     ###     ###       ###             ###
ECHO ###        ####          #########      ##########    ###       ###     #############      ###             ###
ECHO ###          ####        #########      ##########    ###       ###     #############      ###             ###
ECHO ###            ###       ###    ###                    ###     ###     ###         ###     ###             ###
ECHO ###             ###      ###     ###                   ###     ###     ###         ###     ###             ###
ECHO ###              ###     ###      ###                   ###   ###     ###           ###    ###             ###
ECHO ###             ###      ###      ###                   ###   ###     ###           ###     ###            ###
ECHO ###            ###       ###     ###                     ### ###     ###             ###     ###           ###
ECHO ###     #########        ##########                       #####      ###             ###     #########     ###
ECHO ###     ########         #########                        #####     ###               ###     ########     ###
ECHO ###                                                                                                        ###
ECHO ###                                                                                                        ###
ECHO ##############################################################################################################
ECHO ##### Creator not laible for any fines or penalties resulting in misuse ###### Created By: Steven Barkey #####
ECHO ##############################################################################################################
ECHO.
ECHO.

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Move FTP'd .TORRENT files to _auto_load directory for Torrent Client 
ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] ===================== >> "%historylog%"
SET /a "torfilecount=999999"
FOR /F "tokens=*" %%Z IN ('dir /b "%torfiledir%\*.*"') DO (
	If /I "%%~xZ" == ".torrent" (		
		MOVE /Y "X:\sb-avc\_torrent_files\%%Z" "%autoloaddir%\%%Z"
		If NOT EXIST "X:\sb-avc\_torrent_files\%%Z" (
			If EXIST "%autoloaddir%\%%Z" (
				If "!torfilecount!" == "999999" (
					SET /a "torfilecount=1"
				) else (
					SET /a "torfilecount=torfilecount+1"
				)
			)
		)
	)
)
If "!torfilecount!" LSS "999998" (
	ECHO **************************************************************************************************************
	ECHO NOTE: Moved !torfilecount! .torrent file/files from '%torfiledir%' to '%autoloaddir%' directory
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE // Moved !torfilecount! .torrent file/files from '%torfiledir%' to '%autoloaddir%\' directory >> "%historylog%"
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
	ECHO **************************************************************************************************************
	ECHO.
	ECHO.
)

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Create converted/unconverted directories in specified working directory 
ECHO **************************************************************************************************************
If NOT EXIST "%destdir%" (
	MKDIR "%destdir%"
	ECHO *** NOTE: %destdir% - created.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS // Working Directory '%destdir%' created >> "%historylog%"
) else (
	ECHO *** NOTE: %destdir% - ALREADY exists.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE // Working Directory '%destdir%' already exists >> "%historylog%"
)
If NOT EXIST "%convdir%" (
	MKDIR "%convdir%"
	ECHO *** NOTE: %convdir% - created.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS // Working Directory '%convdir%' created >> "%historylog%"
) else (
	ECHO *** NOTE: %convdir% - ALREADY exists.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE // Working Directory '%convdir%' already exists >> "%historylog%"
)
ECHO **************************************************************************************************************
ECHO.
ECHO.

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Set GOTO landing for when multiple sourcedir (Source Directories) are setup
:sourceloop

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Display GLOBAL variables
ECHO ==============================================================================================================
ECHO ===== 
ECHO ===== ***Directories***
ECHO ===== Source Directory: %rootdir%
ECHO ===== Unconverted Directory: %destdir%
ECHO ===== Converted Directory: %convdir%
ECHO ===== Extraction Directory: %extractdir%
ECHO ===== Movie Output Directory: %movieoutputdir%
ECHO ===== Low Quality Movie Output Directory: %lowqualitymovieoutputdir%
ECHO ===== TV Show Output Directory: %tvoutputdir%
ECHO ===== Log Directory: %logdir%
ECHO ===== Auto Load Directory: %autoloaddir%
ECHO ===== Tor File Source Directory: %torfiledir%
ECHO ===== WinRAR Directory: %unrardir%
ECHO ===== Handbrake Directory: %handbrakedir%
ECHO ===== Filebot Directory: %filebotdir%
ECHO ===== 
ECHO ===== ***Defined Files***
ECHO ===== History Log: %historylog%
ECHO ===== File Log: %filelog%
ECHO ===== Plex URL: %plexurl%
ECHO ===== 
ECHO ===== ***Defined Folders***
ECHO ===== TV Show Source Folders: %tvdirectories%
ECHO ===== Skipped Source Folders: %skipdirectories%
ECHO ===== 
ECHO ===== ***Log Settings***
ECHO ===== Log Retention: %logretentiondays% days
ECHO ===== 
ECHO ===== ***Size Restrictions***
ECHO ===== Minimum Size Limit: %minsizelimitbytes%
ECHO ===== Movie Maximum Size Limit: %moviemaxsizelimitbytes%
ECHO ===== TV Show Maximum Size Limit: %tvmaxsizelimitbytes%
ECHO ===== 
ECHO ===== ***Defined Keywords***
ECHO ===== Low Quality Keywords: %lowqualitytext:\=%
ECHO ===== Skipped Keywords: %keywordtext%
ECHO ===== HD Keywords: %hdtext%
ECHO ===== 
ECHO ===== ***Conversion Profiles***
ECHO ===== TV Handbrake Video Quality: %tvhandbrakeprofile%
ECHO ===== HD Handbrake Video Quality: %hdhandbrakeprofile%
ECHO ===== SD Handbrake Video Quality: %sdhandbrakeprofile%
ECHO ===== 
ECHO ===== ***File Extensions***
ECHO ===== Post Conversion Extension: %finalext%
ECHO ===== Approved Source Extensions: %acceptext%
ECHO ===== 
ECHO ==============================================================================================================
ECHO.

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Set loop through folders in the GLOBAL rootdir directory
FOR /f "delims=|" %%A IN ('dir /b "%rootdir%"') DO (

	REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	REM Set appropriate starting loop variables
	SET /a "process=1"
	If NOT !dircounthold! == 1 (
		SET /a "dircount=1"
	)
	SET /a "count=1"
	SET "state=null"
REM	SET "keywordfound=false"
	SET "comparetext=null"
	SET "folderpath=%rootdir%"
	SET "folder=%%A"
	SET "tvfolder=false"
	SET "fileinroot=false"
	SET "mediatype=     "

	REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	REM Start the section with the initial information for organization during output
	ECHO.
	ECHO =========================================================================================START - Folder: !loopcount!====
	CALL ECHO NOTE: Source Directory: %rootdir%\%%A
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE // Source Directory: '%rootdir%\%%A\' >> "%historylog%"

	REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	REM Check against list of directories we want to skip or handle with altered details (tv directories)
	FOR %%B in (%skipdirectories%) DO (
		If "!folder!" == "%%B" (		
			CALL :folderexclusion					
			SET "folderaction=skip"
		)
	)
	If "!state!" == "null" (
		FOR %%F in (%tvdirectories%) DO (
			If NOT "!folder!" == "%%F" (		
				SET "tvfolder=false"
				SET "outputdir=%movieoutputdir%"
				SET "sizelimittype=Movie"
				SET "maxsizelimitbytes=%moviemaxsizelimitbytes%"
			) else (
				SET "tvfolder=true"
				SET "outputdir=%tvoutputdir%"
				ECHO NOTE: TV Show Directory Found
				SET "sizelimittype=TV Show"
				SET "maxsizelimitbytes=%tvmaxsizelimitbytes%"
			)
		)
	) else (
		SET "tvfolder=false"
	)

	REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	REM Check against list of fileextensions we want to do something with
	SET /a "foldercontents=0"
	SET /a "folderfilecount=999999"
	SET "currentext=null"
	If "%%~xA" == ".rar" (
		If "%unrarfiles%" == "true" (
			CALL :extractrar "%rootdir%" "" "%%~nA"
		) else (
			ECHO NOTE: RAR file found, but unrar feature is disabled in the script.
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LOOP //      RAR file found, but unrar feature is disabled in the script >> "%historylog%"
		)
	)
	FOR %%G in (%acceptext%) DO (		
		If "%%~xA" == "%%G" (		
			SET "fileinroot=true"
			If !count! == 1 (					
				ECHO.
				ECHO File located in source root directory, not sub-directory
				ECHO FILE: %%~nA%%~xA
				SET /a "process=2"
				SET /a "folderfilecount=1"
				SET /a "currentext=%%~xA"
				SET "folder="
				SET "filename=%%~nA"
				SET "fileext=%%~xA"
				CALL :checkfortvshow
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      File located in Source Root Directory, not sub-directory >> "%historylog%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      File: '%%~nA%%~xA' >> "%historylog%"
				SET "errorlevel="
				CALL :checkfilerequirements
				CALL :loopoutcome
			)
		)
	)
	If NOT "!fileinroot!" == "true" (
		FOR /F "tokens=*" %%C IN ('dir /b "%rootdir%\%%A\*.*"') DO (
			If "!folderfilecount!" == "999999" (
				SET /a "folderfilecount=1"
			) else (
				SET /a "folderfilecount=folderfilecount+1"
			)
			SET "currentext=%%~xC"
			If "%unrarfiles%" == "true" (
	 			If "%%~xC" == ".rar" (
					CALL :extractrar "%rootdir%" "%%A" "%%~nC"
				)
			)
			FOR %%D in (%acceptext%) DO (		
				If "%%~xC" == "%%D" (		
					If !count! == 1 (					
						ECHO.
						ECHO FILE: %%~nC%%~xC
						SET /a "process=2"
						SET "filename=%%~nC"
						SET "fileext=%%~xC"
						CALL :checkfortvshow
						ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      File: '%%~nC%%~xC' >> "%historylog%"
						SET "errorlevel="
						CALL :checkfilerequirements
						CALL :loopoutcome
					)
				)
			)
		)
	)
	If "!folderfilecount!" LSS "999998" (
		If NOT "!process!" == "2" (
			If NOT "!state!" == "processskip" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LOOP //      No valid file extensions found [Folder Count: "!folderfilecount!", Process Code: "!process!", Final State: "!state!"] >> "%historylog%"
				SET "state=processskip"
			)
		)
	)
	ECHO [INFO] Folder Contents: !foldercontents!
	If "!foldercontents!" == "0" (
		If NOT "!count!" == "0" (
			ECHO NOTE: No matching files to convert in the folder - Safe to delete
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LOOP //      No approved filetypes, Looping to next Source Directory >> "%historylog%"
			SET "state=processskip"
		)
	)
	If "!folderfilecount!" == "999999" (
		If NOT "!state!" == "processskip" (
			ECHO NOTE: No matching files to convert in the folder - Safe to delete
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LOOP //      No files found in directory >> "%historylog%"
			SET "state=processskip"
		)
	)

	REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	REM Increase loopcount and close section for next pass
	ECHO =========================================================================================END - Folder: !loopcount!======
	ECHO.
	SET "mediatype=     "
	SET /a "loopcount=loopcount+1"
	SET /a "friendlysize=0"
)
SET /a "dircounttemp=dircount+1"
CALL SET "nextfolderpath=%%sourcedir[!dircounttemp!]%%"
If NOT "!nextfolderpath!" == "" ( 
	SET /a "dircounthold=1"	
	SET /a "dircount=!dircounttemp!"
	SET "rootdir=!nextfolderpath!"
	ECHO.
	ECHO.
	ECHO --------------------------------------------------------------------------------------------------------------
	ECHO ----------------------------------- NEXT: Looping to next source directory -----------------------------------
	ECHO --------------------------------------------------------------------------------------------------------------
	ECHO.
	ECHO.
	ECHO.
	GOTO :sourceloop
)

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Remove converted/unconverted directories in specified working directory
ECHO.
ECHO **************************************************************************************************************
RD /S /Q "%workingdir%"
If EXIST "%workingdir%" (
	ECHO *** NOTE: %workingdir% - NOT removed.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL // [ALERT] Working directory '%workingdir%' not successfully removed >> "%historylog%"
) else (
	ECHO *** NOTE: %workingdir% - successfully removed.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS // Working Directory '%workingdir%' successfully removed >> "%historylog%"
)
ECHO **************************************************************************************************************

REM ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REM Reboot Plex Media Server to fix an issue where the PMS server is not accessible after the daily (morning) reboot of the network router
If "%rescanplex%" == "true" (
	SET /a "hourcheck=!time:~0,2!"
	If !hourcheck! LSS %rebootcutoffhour% (
		TASKKILL /F /IM "Plex Media Server.exe" /T
		START /B C:\Progra~2\Plex\Plexme~1\"Plex Media Server.exe" 
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE // Restarting Plex Media Server >> "%historylog%"
		ECHO NOTE: Restarting Plex Media Server, please wait
		TIMEOUT 5
	)
	FOR /L %%T IN (6,-1,0) DO (
		TASKLIST /FI "IMAGENAME EQ Plex Media Server.exe" | find ":" > nul
		If !errorlevel! == 0 (
			If !hourcheck! LSS %rebootcutoffhour% (
				If %%T LSS 1 (
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      Plex Media Server failed to restart successfully >> "%historylog%"
	REM			SET "mediaplayerscan=false" & REM Stop plexupdatelib from occuring since the Plex Media Server is down
					SET "alertpopup=Plex Media Server failed to restart successfully!"
					ECHO FAIL: !alertpopup!
					SET "showalert=true"
					ECHO !alertpopup! >> "%alertfile%"
					ECHO. >> "%alertfile%"
				) else (
					TIMEOUT 5
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Plex Media Server has not restarted yet, will try again >> "%historylog%"
					ECHO NOTE: Plex Media Server has not restarted yet, will try again
				)
			) else (
				SET "alertpopup=Plex Media Server is not running and must be manually started!"
				ECHO FAIL: !alertpopup!
				SET "showalert=true"
				ECHO !alertpopup! >> "%alertfile%"
				ECHO. >> "%alertfile%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL // !alertpopup! >> "%historylog%"
			)
		) else (
			If !errorlevel! == 1 (
				If NOT "!plexrestartedsuccessfully!" == "true" (
					If !hourcheck! LSS %rebootcutoffhour% (
						ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS //      Plex Media Server restarted successfully >> "%historylog%"
						ECHO NOTE: Plex Media Server restarted successfully
					) else (
						ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
						ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS // Plex Media Server is already running >> "%historylog%"
						ECHO NOTE: Plex Media Server is already running
					)
					If "%mediaplayerscan%" == "true" (
						REM Plex Libraries: Movies = 1, TV Shows = 3
						If "%moviemediaplayerscan%" == "true" (
							CALL :plexupdatelib "%plexurl%/library/sections/1/refresh" "Movies"
						)
						If "%tvmediaplayerscan%" == "true" (
							CALL :plexupdatelib "%plexurl%/library/sections/3/refresh" "TV Shows"
						)
					) else (
						ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // SKIP //      No content added, Plex refresh request ignored >> "%historylog%"
					)
					SET "plexrestartedsuccessfully=true"
				)
			)
		)
	)
)

CALL :logcleanup

REM SHUTDOWN /r /m \\SBHOME_TOR /c "Scripted Reboot" /f /d p:4:1 /t 15

If "%showalert%" == "true" (
	TYPE "%alertfile%" | MSG *
)
DEL "%alertfile%"

If "%pauseatend%" == "true" (
	PAUSE
)
GOTO :eof

:folderexclusion
ECHO FAIL: Directory in listed in the exclude list
ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // SKIP //      Directory in listed in the exclude list >> "%historylog%"
SET "state=processskip"
SET /a "count=0"
EXIT /B

:extractrar
SET "extractrarpath=%1"
SET "extractrarfolder=%2"
SET "extractrarfile=%3"
SET "extractrarfull=!extractrarpath!\!extractrarfolder!\!extractrarfile!.rar"
SET "extractrarstate=unknown"
If NOT EXIST "%extractdir%" (
	MKDIR "%extractdir%"
	ECHO *** NOTE: %extractdir% - created.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      RAR Extraction Directory '%extractdir%' created >> "%historylog%"
) else (
	ECHO *** NOTE: %extractdir% - ALREADY exists.
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      RAR Extraction Directory '%extractdir%' already exists >> "%historylog%"
)
FOR /F "tokens=*" %%I IN ('dir /b "!extractrarpath!\!extractrarfolder!\*.*"') DO (
	FOR %%J in (%acceptext%) DO (
		If "%%~xI" == "%%J" (
			SET "extractrarstate=found"
			SET "extractrarext=%%~xI"
		)
	)
)
If "!extractrarstate!" == "found" (
	ECHO FAIL: The '.rar' file is already extracted
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      RAR File: !extractrarfile:~1,-1!.rar >> "%historylog%"
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // SKIP //      An '!extractrarext!' file was already extracted from the .rar file >> "%historylog%"
) else (
	FOR %%K in (%acceptext%) DO (
		"%unrardir%\UnRAR.exe" x -o+ !extractrarfull! *%%K "%extractdir%\"
		FOR /F "tokens=*" %%L IN ('dir /b "%extractdir%\*.*"') DO (
			FOR %%M in (%acceptext%) DO (
				If "%%~xL" == "%%M" (
					MOVE /Y "%extractdir%\%%~nL%%~xL" "!extractrarpath!\!extractrarfolder!\%%~nL%%~xL"
				)
			)
		)
	)
	FOR /F "tokens=*" %%N IN ('dir /b "!extractrarpath!\!extractrarfolder!\*.*"') DO (
		FOR %%O in (%acceptext%) DO (
			If "%%~xN" == "%%O" (
				SET "extractrarstate=extracted"
				SET "extractrarext=%%~xN"
			)
		)
	)
	If "!extractrarstate!" == "extracted" (
		ECHO PASS: An '!extractrarext!' file was succcessfully extracted from the .rar file and will be processed on the next scheduled run
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      RAR File: !extractrarfile:~1,-1!.rar >> "%historylog%"
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      An '!extractrarext!' file was succcessfully extracted from the .rar file and will be processed on the next scheduled run >> "%historylog%"
	) else (
		ECHO FAIL: The '.rar' file did not contain any approved file types
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      RAR File: !extractrarfile:~1,-1!.rar >> "%historylog%"
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] The '.rar' file did not contain any approved file types >> "%historylog%"
	)
)
EXIT /B

:checkfortvshow
ECHO NOTE: Checking for TV Show indicators
ECHO.!filename! | FINDSTR /R /I "S[0-9][0-9]E[0-9][0-9]" >Nul && ( 
	ECHO NOTE: Found 'S##E##' in Filename
	SET "tvfolder=true"
	SET "outputdir=%tvoutputdir%"
)
ECHO.!folder! | FINDSTR /R /I "S[0-9][0-9]E[0-9][0-9]" >Nul && ( 
	ECHO NOTE: Found 'S##E##' in Folder
	SET "tvfolder=true"
	SET "outputdir=%tvoutputdir%"
)
If "!tvfolder!" == "true" (
	ECHO NOTE: File Identified as a TV Show
	SET "mediatype=TV   "
	SET "sizelimittype=TV Show"
	SET "maxsizelimitbytes=%tvmaxsizelimitbytes%"
) else (	
	SET "mediatype=MOVIE"
	SET "sizelimittype=Movie"
	SET "maxsizelimitbytes=%moviemaxsizelimitbytes%"
	ECHO NOTE: File Identified as a Movie
	ECHO NOTE: Checking for Low Quality identifiers
	FOR %%R in (%lowqualitytext%) DO (
		SET "neddle=%%R"
		SET "neddle=!neddle:~1,-1!"
		SET "dispneddle=!neddle:\=!"
		ECHO.!filename! | FINDSTR /I /c:"!neddle!" >Nul && (
			If !errorlevel! == 0 (
				If "%lowqualitycheck%" == "true" (
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Found '!dispneddle!' in the filename, indicating the source is low quality >> "%historylog%"
					ECHO NOTE: Found '!dispneddle!' in the filename, indicating the source is low quality
					SET "outputdir=%lowqualitymovieoutputdir%"
				) else (
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LOOP //      Low Quality file found, but Low Quality sorting feature is disabled in the script >> "%historylog%"
					ECHO NOTE: Low Quality file found, but Low Quality sorting feature is disabled in the script.
				)
			)
		)
	)
)
ECHO NOTE: Output Directory: !outputdir!
If "!folderfilecount!" GTR "1" (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // LOOP //    ***** Multiple files found in the Source Directory, looping to next file ***** >> "%historylog%"
	REM ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
)
ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Output Directory: '!outputdir!' >> "%historylog%"
EXIT /B

:checkforresolution
ECHO NOTE: Checking for video resolution indicators to apply the appropriate conversion settings
SET "resolution=sd"
SET "handbrakeprofiledisp=unknown"
FOR %%P in (%hdtext%) DO (
	ECHO.!filename! | FINDSTR /R /I "%%P" >Nul && ( 
		ECHO NOTE: Found '%%P' in Filename
		SET "resolution=hd"
	)
)
If "!tvfolder!" == "true" (
	ECHO NOTE: Using TV Show profile
	SET "handbrakeprofile=%tvhandbrakeprofile%"
	SET "handbrakeprofiledisp=!tvhandbrakeprofiledisp!"
) else (
	If "!resolution!" == "hd" (
		ECHO NOTE: Found HD indicators
		SET "handbrakeprofile=%hdhandbrakeprofile%"
		SET "handbrakeprofiledisp=!hdhandbrakeprofiledisp!"
	) else (
		ECHO NOTE: Did not find any HD indicators
		SET "handbrakeprofile=%sdhandbrakeprofile%"
		SET "handbrakeprofiledisp=!sdhandbrakeprofiledisp!"
	)
)

ECHO NOTE: Handbrake Profile !handbrakeprofiledisp! selected [Video Quality: !handbrakeprofile!] [TV: %tvhandbrakeprofile%, HD: %hdhandbrakeprofile%, SD: %sdhandbrakeprofile%]
ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Handbrake Profile '!handbrakeprofiledisp!' selected [Video Quality '!handbrakeprofile!'] [TV: %tvhandbrakeprofile%, HD: %hdhandbrakeprofile%, SD: %sdhandbrakeprofile%] >> "%historylog%"
EXIT /B

:checkfilerequirements
ECHO PASS: Approved file extension match found for '!fileext!'
FOR %%E IN ("!folderpath!\!folder!\!filename!!fileext!") DO (
	CALL :userfriendlysize %%~zE
	If %%~zE GTR %minsizelimitbytes% (  
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      Minimum filesize of '%minsizelimitbytes%' bytes met >> "%historylog%"
		ECHO PASS: Filesize: %%~zE bytes [!friendlysize!] - Over MINIMUM filesize requirement of %minsizelimitbytes% bytes
		SET "keywordfound=false"
		FOR %%Q in (%keywordtext%) DO (
			ECHO.!filename! | FINDSTR /I "%%Q" >Nul && ( 
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // SKIP //      Keyword '%%Q' found >> "%historylog%"
				ECHO FAIL: Keyword '%%Q' found
				SET "state=processskip"
				SET "keywordfound=true"
			)
		)
		If NOT "!keywordfound!" == "true" (
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      Keywords not found >> "%historylog%"
			ECHO PASS: Keywords not found
			SET "processedstr=!processedstr!"!filename!", "
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Added filename to Processed Log double-check list for added de-duplication protection. >> "%historylog%"
			If %%~zE LSS !maxsizelimitbytes! (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Filesize: %%~zE bytes [!friendlysize!] >> "%historylog%"
				ECHO PASS: Filesize: %%~zE bytes - over minimum limit and under maximum limit
				If "!fileext!" == "%finalext%" (
					FINDSTR /c:"!filename!" %filelog%
					If !errorlevel! == 0 (
						ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // SKIP //      [ALERT] File with matching filename already processed >> "%historylog%"
						ECHO SKIP: File with matching filename already processed
						SET "state=processskip"	
					) else (
						COPY "!folderpath!\!folder!\!filename!!fileext!" "!outputdir!\!filename!!fileext!"
						If EXIST "!outputdir!\!filename!!fileext!" (
							ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // COPY // !friendlysize! // !filename! // !outputdir! >> "%filelog%"
							FINDSTR /c:"!filename!" %filelog%
							If !errorlevel! == 0 (
								ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      Filename added to vac_files.log >> "%historylog%"
								ECHO PASS: Filename added to vac_processed_files.log
								REM SET "processedstr=!processedstr!, !filename!, "
							)
							ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      File already in %finalext% format, and file successfully copied to output directory >> "%historylog%"
							ECHO PASS: File already in correct format, file copied successfully
							ECHO NOTE: %historylog% updated successfully
							CALL :filecleanup
							If "!cleanup!" == "complete" (
								ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      File cleanup completed successfully >> "%historylog%"
								ECHO PASS: File cleanup complete
								SET "state=processdone"
							) else (
								ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] File cleanup failed >> "%historylog%"
								ECHO FAIL: File cleanup failed
								SET "state=processfail"
							)
						) else (
							ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] File already in %finalext% format, but copy failed >> "%historylog%"
							ECHO PASS: File already in correct format, but error occured during copy
							SET "state=processfail"
						)
					)
				) else (
					SET /a "process=3"
				)
			) else (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Filesize: %%~zE bytes [!friendlysize!] >> "%historylog%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Exceeds maximum !sizelimittype! filesize limit of !maxsizelimitbytes! bytes, conversion required >> "%historylog%"
				ECHO FAIL: Filesize: %%~zE bytes [!friendlysize!] - Over MAXIMUM !sizelimittype! filesize limit of !maxsizelimitbytes! bytes, conversion required.
				SET /a "process=3"
			)
		)
		If !process! == 3 (
			FINDSTR /c:"!filename!" %filelog%
			If !errorlevel! == 0 (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // SKIP //      [ALERT] File with matching filename already processed >> "%historylog%"
				ECHO SKIP: File with matching filename already processed
				SET "state=processskip"	
			) else (
				CALL :convertfile
			)
		) else (
			If !state! == "processfail" (
				ECHO FAIL: File failed requirements - Not converting
				SET "state=processskip"
			)
		)
	) else (
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // NOTE //      Filesize: %%~zE bytes [!friendlysize!] >> "%historylog%"
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] Under MINIMUM !sizelimittype! filesize limit of %minsizelimitbytes% bytes, file skipped >> "%historylog%"
		ECHO FAIL: Filesize: %%~zE bytes [!friendlysize!] - Under MINIMUM !sizelimittype! filesize limit of %minsizelimitbytes% bytes
		SET "state=processskip"
	)
)
EXIT /B

:convertfile
ECHO PASS: File passed requirements - Proceeding to the conversion to %finalext%
ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      File passed requirements.  Now proceeding to the conversion to '%finalext%' >> "%historylog%"
COPY "!folderpath!\!folder!\!filename!!fileext!" "%destdir%\!filename!!fileext!"
If EXIST "%destdir%\!filename!!fileext!" (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      File copied from source to unconverted directory >> "%historylog%"
	ECHO PASS: File copied from source to unconverted working directory
	CALL :checkforresolution
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      File conversion to '%finalext%' started >> "%historylog%"
	ECHO PASS: File conversion to %finalext% started
	SET "starttime=!time!"
	"%handbrakedir%\HandBrakeCLI" -i "%destdir%\!filename!!fileext!" -o "%convdir%\!filename!%finalext%" -f !finalext:~1!  -e x264 -q !handbrakeprofile!  --encoder-preset=veryfast  --encoder-tune="film"  --encoder-level="4.0"  --encoder-profile=main 
REM	"%handbrakedir%\HandBrakeCLI" -i "%destdir%\!filename!!fileext!" -o "%convdir%\!filename!%finalext%" --preset="!handbrakeprofile!"
	If EXIST "%convdir%\!filename!%finalext%" (
		SET "endtime=!time!"
		CALL :elapsedtime !starttime! !endtime! timedifference
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      File conversion to '%finalext%' completed [Conversion Time: !requiredtime!] >> "%historylog%"
		ECHO PASS: Conversion to %finalext% completed [Conversion Time: !timedifference!]
		SET "originalfriendlysize=unknown"
		FOR %%H IN ("%convdir%\!filename!%finalext%") DO (
			If "!fileext!" == "%finalext%" (
				If %%~zH GTR %%~zE (
					COPY "!folderpath!\!folder!\!filename!!fileext!" "!outputdir!\!filename!!fileext!"
					SET "comparetext=Original '!fileext!' file is smaller [%%~zE bytes - !friendlysize!], copied to output directory successfully"
				) else (
					SET "originalfriendlysize=!friendlysize!"
					CALL :userfriendlysize %%~zH
					MOVE /Y "%convdir%\!filename!%finalext%" "!outputdir!\!filename!%finalext%"
					SET "comparetext=Converted '%finalext%' file is smaller [%%~zH bytes - !friendlysize!], copied to output directory successfully"
				)
			) else (
				SET "originalfriendlysize=!friendlysize!"
				CALL :userfriendlysize %%~zH
				MOVE /Y "%convdir%\!filename!%finalext%" "!outputdir!\!filename!%finalext%"
				SET "comparetext=Original file was '!fileext!', copied newly converted '%finalext%' file [%%~zH bytes - !friendlysize!] to output directory successfully"
			)
		)
		If EXIST "!outputdir!\!filename!%finalext%" (
			If "!originalfriendlysize!" == "unknwon" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // COPY // !friendlysize! // !filename! // !outputdir! >> "%filelog%"
			) else (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // CONV // !originalfriendlysize! to !friendlysize! // !handbrakeprofiledisp! // !filename! // !outputdir! >> "%filelog%"
			)
			FINDSTR /c:"!filename!" %filelog%
			If !errorlevel! == 0 (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      Filename added to vac_processed_files.log >> "%historylog%"
				ECHO PASS: Filename added to vac_processed_files.log
				REM SET "processedstr=!processedstr!, !filename!, "
			)
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      !comparetext! >> "%historylog%"
			ECHO PASS: !comparetext!
			ECHO NOTE: %historylog% updated successfully
			CALL :filecleanup
			If "!cleanup!" == "complete" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      File cleanup completed successfully >> "%historylog%"
				ECHO PASS: File cleanup complete
				SET "state=processdone"
			) else (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] File cleanup failed >> "%historylog%"
				ECHO FAIL: File cleanup failed
				SET "state=processfail"
			)
		) else (
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] After conversion, file not copied to output directory successfully >> "%historylog%"
			ECHO FAIL: After conversion, file not copied to output directory successfully
			SET "state=processfail"
		)
	) else (
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] Conversion to '%finalext%' failed >> "%historylog%"
		ECHO FAIL: Conversion to %finalext% failed
	)
) else (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] File not copied from source to unconverted directory >> "%historylog%"
	ECHO FAIL: File NOT copied from source to unconverted working directory
)
EXIT /B

:userfriendlysize bytes
REM SET /a "friendlysize=%1/1024"
REM If !friendlysize! GTR 1048576 (
If %1 GTR 1073741825 (
	SET /a "friendlysize=%1/1024"
	SET /a "friendlysize=!friendlysize! / 1024"
	SET /a "friendlysize=!friendlysize! * 1000"
	SET /a "friendlysize=!friendlysize! / 1024"
	SET "whole=!friendlysize:~0,-3!"	
	SET "decimal=!friendlysize:~1,-1!"
	SET "friendlysize=~!whole!.!decimal! GB"
) else (
	SET /a "friendlysize=%1/1024"
	SET /a "friendlysize=!friendlysize! * 1000"
	SET /a "friendlysize=!friendlysize! / 1024"
	If !friendlysize! GTR 9999 (
		SET "whole=!friendlysize:~0,-3!"
		SET "decimal=!friendlysize:~3,-1!"
	) else (
		If !friendlysize! GTR 999 (
			SET "whole=!friendlysize:~0,-3!"
			SET "decimal=!friendlysize:~2,-1!"
		) else (
			SET "whole=!friendlysize:~0,-2!"
			SET "decimal=!friendlysize:~1!"
		)
	)		
	REM SET "friendlysize=~!whole!.!decimal! MB"
	SET "friendlysize=~!whole! MB"
)
If "!friendlysize!" == "~. GB" (
	SET "friendlysize=2.0+ GB"
)
EXIT /B

:filecleanup
SET "mediaplayerscan=true"
If EXIST "%destdir%\!filename!!fileext!" (
	DEL "%destdir%\!filename!!fileext!"
)
If EXIST "%convdir%\!filename!!fileext!" (
	DEL "%convdir%\!filename!!fileext!"
)
If NOT EXIST "%destdir%\!filename!!fileext!" (
	If NOT EXIST "%convdir%\!filename!!fileext!" (
		SET "cleanup=complete"
		SET /a "foldercontents=foldercontents+1"
	) else (
		SET "cleanup=fail"
	)
) else (
	SET "cleanup=fail"
)
If "!tvfolder!" == "true" (
	CALL :tvorganize
	SET "tvmediaplayerscan=true"
) else (
	SET "moviemediaplayerscan=true"
)
EXIT /B

:tvorganize
ECHO NOTE: Starting TV Show Organizer, FileBot
"%filebotdir%\filebot" -rename "!outputdir!\!filename!%finalext%" --db "TheTVDB" -non-strict --format "{n}/{'Season '+s}/{n} - {s00e00} - {t}"
If NOT EXIST "!outputdir!\!filename!%finalext%" (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      TV Show organization completed successfully >> "%historylog%"
) else (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] TV Show organization failed >> "%historylog%"
	SET "alertpopup=TV Show organization failed for !filename!%finalext%"
	ECHO FAIL: !alertpopup!
	SET "showalert=true"
	ECHO !alertpopup! >> "%alertfile%"
	ECHO. >> "%alertfile%"
)
EXIT /B

:loopoutcome
If "!state!" == "processskip" (
	ECHO FAIL: Process skipped - Proceeding to next object	
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LAST //      Process Outcome: SKIP >> "%historylog%"
)
If "!state!" == "processfail" (
	ECHO FAIL: Process failed - Proceeding to next object	
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LAST //      [ALERT] Process Outcome: FAIL >> "%historylog%"
)
If "!state!" == "processdone" (
	ECHO PASS: Process complete - Proceeding to next object	
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LAST //      Process Outcome: DONE >> "%historylog%"
)
If "!state!" == "null" (
	ECHO FAIL: Process status unknown - Proceeding to next object	
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // LAST //      [ALERT] Process Outcome: UNKNOWN >> "%historylog%"
)
EXIT /B

:plexupdatelib
SET "pulurl=%~1"
SET "pullib=%~2"
SET "libupdate=false"
START HH "%pulurl%"
TIMEOUT 2
TASKLIST /FI "IMAGENAME EQ hh.exe" | find ":" > nul
If errorlevel 1 TASKKILL /F /IM "hh.exe"&SET "libupdate=true"
If "%libupdate%" == "true" (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // PASS //      Plex '!pullib!' refresh request completed >> "%historylog%"
) else (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !mediatype! // FAIL //      [ALERT] Plex '!pullib!' refresh request failed >> "%historylog%"
)
EXIT /B

:logcleanup
MOVE /Y "%filelog%" "%logdir%\vac_processed_files - ROLLING_BACKUP.log"
If NOT EXIST "%filelog%" (
	If EXIST "%logdir%\vac_processed_files - ROLLING_BACKUP.log" (
		FOR /L %%V IN (%logretentiondays%,-1,0) DO ( 
			Call :ScrubLog -%%V returndate
			If "%%V" == "%logretentiondays%" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%historylog%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS // Processed Log Cleanup process started >> "%historylog%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS //      Processed Log successfully relocated to ROLLING BACKUP for retention purposes and so log scrubbing can occur  >> "%historylog%"					
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Log retention set to %logretentiondays% days [!returndate! through !date:~4,2!-!date:~7,2!-!date:~10,4!] >> "%historylog%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Retaining previously Processed Log items [%logretentiondays% days] for added de-duplication protection >> "%historylog%"
				ECHO NOTE: Retaining Processed Log items for !returndate! through !date:~4,2!-!date:~7,2!-!date:~10,4!
			)
			FINDSTR /B "[!returndate! " "%logdir%\vac_processed_files - ROLLING_BACKUP.log" >> "%logdir%\temp-vac_processed_files.log"
			ECHO NOTE: Retaining Processed Log items from %%V days ago [!returndate!]
		)
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Checking to insure current items are in the temp Processed Log >> "%historylog%"
		FOR %%U in (!processedstr!) DO (				
			SET "neddle=%%U"
			FINDSTR /c:"!neddle:~1,-1!" "%logdir%\temp-vac_processed_files.log"
			If !errorlevel! == 0 (
				ECHO SKIP: '!neddle:~1,-1!' already listed in temp processed log
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Skipping '!neddle:~1,-1!' as it is already listed in temp Processed Log >> "%historylog%"
			) else (
				FINDSTR /c:"!neddle:~1,-1!" "%logdir%\vac_processed_files - ROLLING_BACKUP.log" >> "%logdir%\temp-vac_processed_files.log"
				ECHO Added '!neddle:~1,-1!' to the temp processed log
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Added '!neddle:~1,-1!' to the temp Processed Log >> "%historylog%"
			)
		)
		MOVE /Y "%logdir%\temp-vac_processed_files.log" "%filelog%"
		If EXIST "%filelog%" (
			If NOT EXIST "%logdir%\temp-vac_processed_files.log" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS //      Temp Processed Log moved to official Processed Log >> "%historylog%"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS //      Processed Log cleanup process completed >> "%historylog%"
			) else (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] Processed Log cleanup process failed to delete the temp log file >> "%historylog%"
				ECHO FAIL: LOG CLEANUP PROCESS FAILED TO REMOVE TEMP LOG FILE!
			)
		) else (
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] Processed Log cleanup process failed to create new scrubbed log file >> "%historylog%"
			MOVE /Y "%logdir%\temp-vac_processed_files.log" "%filelog%"
			ECHO FAIL: PROCESSED LOG CLEANUP PROCESS FAILED TO CREATE NEW SCRUBBED PROCESSED LOG FILE!
			If NOT EXIST "%filelog%" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] ATTEMPT TO FORCE-CONVERT UNSCRUBBED TEMP PROCESSED LOG INTO OFFICIAL PROCESSED LOG FAILED! >> "%historylog%"
				ECHO FAIL: ATTEMPT TO FORCE-CONVERT UNSCRUBBED TEMP PROCESSED LOG INTO OFFICIAL PROCESSED LOG FAILED!
			) else (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] HAD TO FORCE-CONVERT UNSCRUBBED TEMP PROCESSED LOG INTO OFFICIAL PROCESSED LOG! >> "%historylog%"
				ECHO FAIL: HAD TO FORCE-CONVERT UNSCRUBBED TEMP PROCESSED LOG INTO OFFICIAL PROCESSED LOG!
			)
		)
	) else (
		SET "alertpopup=PROCESSED LOG CLEANUP PROCESS FAILED AND NEITHER SCRUBBED OR ROLLING BACKUP PROCESSED LOGS EXIST!"
		ECHO FAIL: !alertpopup!
		SET "showalert=true"
		ECHO !alertpopup! >> "%alertfile%"
		ECHO. >> "%alertfile%"
	)
) else (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL // [ALERT] Processed Log cleanup process failed to move log to a ROLLING BACKIP location for scrubbing >> "%historylog%"
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Processed Log cleanup process failed to move log to a ROLLING BACKIP location for scrubbing >> "%historylog%"
)
COPY "%historylog%" "%logdir%\vac_history - ROLLING_BACKUP.log"
MOVE /Y "%historylog%" "%logdir%\temp-vac_history.log"
If NOT EXIST "%historylog%" (
	If EXIST "%logdir%\temp-vac_history.log" (
		FOR /L %%W IN (%logretentiondays%,-1,0) DO ( 
			CALL :ScrubLog -%%W returndate
			If "%%W" == "%logretentiondays%" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] >> "%logdir%\temp-vac_history.log"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS // History Log Cleanup process started>> "%logdir%\temp-vac_history.log"
				If EXIST "%logdir%\vac_history - ROLLING_BACKUP.log" (
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS //      History Log successfully copied to ROLLING BACKUP for retention purposes  >> "%logdir%\temp-vac_history.log"					
				) else (
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] History Log was NOT successfully relocated to ROLLING BACKUP for retention purposes  >> "%logdir%\temp-vac_history.log"					
				)
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS //      History Log successfully relocated to temporary location so log scrubbing can occur  >> "%logdir%\temp-vac_history.log"
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Log retention set to %logretentiondays% days [!returndate! through !date:~4,2!-!date:~7,2!-!date:~10,4!] >> "%logdir%\temp-vac_history.log"				
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      Started scrubbing History Log for items older than !returndate! >> "%logdir%\temp-vac_history.log"
				ECHO NOTE: Retaining Processed Log items for !returndate! through !date:~4,2!-!date:~7,2!-!date:~10,4!
			)
			FINDSTR /B "[!returndate! " "%logdir%\temp-vac_history.log" >> "%historylog%"
			ECHO NOTE: Retaining History Log items from %%W days ago [!returndate!]
		)
		If EXIST "%historylog%" (
			DEL "%logdir%\temp-vac_history.log"
			If NOT EXIST "%logdir%\temp-vac_history.log" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // PASS //      History Log cleanup process completed >> "%historylog%"
			) else (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] History Log cleanup process failed to delete the temp log file >> "%historylog%"
				ECHO FAIL: LOG CLEANUP PROCESS FAILED TO REMOVE TEMP LOG FILE!
			)
		) else (
			ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] History Log cleanup process failed to create new scrubbed log file >> "%logdir%\temp-vac_history.log"
			MOVE /Y "%logdir%\temp-vac_history.log" "%historylog%"
			ECHO FAIL: HISTORY LOG CLEANUP PROCESS FAILED TO CREATE NEW SCRUBBED HISTORY LOG FILE!
			If NOT EXIST "%historylog%" (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] ATTEMPT TO FORCE-CONVERT UNSCRUBBED TEMP HISTORY LOG INTO OFFICIAL LOG FAILED! >> "%logdir%\temp-vac_history.log"
				ECHO FAIL: ATTEMPT TO FORCE-CONVERT UNSCRUBBED TEMP HISTORY LOG INTO OFFICIAL LOG FAILED!
			) else (
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL //      [ALERT] HAD TO FORCE-CONVERT UNSCRUBBED TEMP HISTORY LOG INTO OFFICIAL LOG! >> "%historylog%"
				ECHO FAIL: HAD TO FORCE-CONVERT UNSCRUBBED TEMP HISTORY LOG INTO OFFICIAL LOG!
			)
		)
	) else (
		SET "alertpopup=HISTORY LOG CLEANUP PROCESS FAILED AND NEITHER SCRUBBED OR TEMP HISTORY LOGS EXIST!"
		ECHO FAIL: !alertpopup!
		SET "showalert=true"
		ECHO !alertpopup! >> "%alertfile%"
		ECHO. >> "%alertfile%"
	)
) else (
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // FAIL // [ALERT] History Log cleanup process failed to move log to a temporary location for scrubbing >> "%historylog%"
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] //       // NOTE //      History Log cleanup process failed to move log to a temporary location for scrubbing >> "%historylog"
)
EXIT /B

:ScrubLog <+/-Days> returndate
::Adapted from DosTips Functions::
setlocal
SET a=%1
SET "yy=!date:~10,4!"
SET "mm=!date:~4,2!"
SET "dd=!date:~7,2!"
SET /a "yy=10000%yy% %%10000,mm=100%mm% %% 100,dd=100%dd% %% 100"
If %yy% LSS 100 (
	SET /a yy+=2000 &rem Adds 2000 to two digit years
)
SET /a JD=dd-32075+1461*(yy+4800+(mm-14)/12)/4+367*(mm-2-(mm-14)/12*12)/12-3*((yy+4900+(mm-14)/12)/100)/4
If %a:~0,1% equ + (
	SET /a JD=%JD%+%a:~1%
) else (
	SET /a JD=%JD%-%a:~1%
)
SET /a L= %JD%+68569,     N= 4*L/146097, L= L-(146097*N+3)/4, I= 4000*(L+1)/1461001
SET /a L= L-1461*I/4+31, J= 80*L/2447,  K= L-2447*J/80,      L= J/11
SET /a J= J+2-12*L,      I= 100*(N-49)+I+L
SET /a YYYY= I, MM=100+J, DD=100+K
SET MM=%MM:~-2%
SET DD=%DD:~-2%
SET ret=%MM: =%-%DD: =%-%YYYY: =%
endlocal & set %~2=%ret%
EXIT /B

:elapsedtime starttime endtime timedifference
SET starttime=%1
SET endtime=%2
REM SET /A starttime=(1!starttime:~0,2!-100)*360000 + (1!starttime:~3,2!-100)*6000 + (1!starttime:~6,2!-100)*100 + (1!starttime:~9,2!-100)
REM SET /A endtime=(1!endtime:~0,2!-100)*360000 + (1!endtime:~3,2!-100)*6000 + (1!endtime:~6,2!-100)*100 + (1!endtime:~9,2!-100)

SET /A starttimecalc=(1!starttime:~0,2!-100)*360000
SET /A starttimecalc=!starttimecalc! + (1!starttime:~3,2!-100)*6000
SET /A starttimecalc=!starttimecalc! + (1!starttime:~6,2!-100)*100
SET /A starttimecalc=!starttimecalc! + (1!starttime:~9,2!-100)
SET /A starttime=!starttimecalc!

SET /A endtimecalc=(1!endtime:~0,2!-100)*360000
SET /A endtimecalc=!endtimecalc! + (1!endtime:~3,2!-100)*6000
SET /A endtimecalc=!endtimecalc! + (1!endtime:~6,2!-100)*100
SET /A endtimecalc=!endtimecalc! + (1!endtime:~9,2!-100)
SET /A endtime=!endtimecalc!

If !endtime! LSS !starttime! (
	SET /A duration=!starttime!-!endtime!
) else (
	SET /A duration=!endtime!-!starttime!
)

SET /A durationh= !duration! / 360000 
SET /A durationm=(!duration! - !durationh!*360000) / 6000
SET /A durations=(!duration! - !durationh!*360000 - !durationm!*6000) / 100
SET /A durationhs=(!duration! - !durationh!*360000 - !durationm!*6000 - !durations!*100)

If !durationh! LSS 10 (
	SET "durationh=0!durationh!"
)
If !durationm! LSS 10 (
	SET "durationm=0!durationm!"
)
If !durations! LSS 10 (
	SET "durations=0!durations!"
)
If !durationhs! LSS 10 (
	SET "durationhs=0!durationhs!"
)
SET "requiredtime=!durationh!:!durationm!:!durations!.!durationhs! -- 1/100 seconds: !duration!"
SET %~3=%requiredtime%
EXIT /B