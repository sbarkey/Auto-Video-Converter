@ECHO OFF
setlocal EnableDelayedExpansion

REM \\sbhome_nas\Resources\Scripts\video_readyfiles.bat "~New.Girl.S05E17.720p.HDTV.x264-AVS.[VTV].mkv~" "~ShowRSS~" "~D:\Media Downloads\_active~"

REM Get the passed variables from torrent client
SET "filelog=\\SBHOME_NAS\Resources\Scripts\vac_ready_files.log"
REM SET "filelog=\\SBHOME_NAS\Resources\Scripts\vac_history.log"	
SET "file=%1"
SET "label=%2"
SET "savedir=%3"
SET "copy=false"
SET "utsavedir=D:\Media Downloads\_active"

REM Remove the leading and trailing characters that seperate the passed variables
SET "file=%file:~2%
SET "file=%file:~0,-1%
SET "label=%label:~2%
SET "label=%label:~0,-1%
SET "savedir=%savedir:~2%
SET "savedir=%savedir:~0,-1%
SET "copytodir=%savedir:_active=_complete_downloads\default%

REM Check to see if the uT client successfully moved the file to the completed directory for AVC processing
If NOT !savedir! == !copytodir! ( 
	REM Check to see if the file is in the source completed downloads folder, meaning it is a single file
	If "!savedir!" == "!utsavedir!" (
		SET "copy=true"
	)
	REM Check to make sure the destination completed downloads folder does not exists (eg. the subfolder for the torrent was not already created)
	If NOT EXIST !copytodir! (
		SET "copy=true"		
	)
	REM Check to see if the torrent/torrent folder needs to be copied
	If !copy! == true ( 
		REM Check to see if the torrent has its own sub-folder
		If "!savedir!" == "!utsavedir!" ( 
			If NOT EXIST "!copytodir!\!file!" (
				COPY "!savedir!\!file!" "!copytodir!\!file!"
				REM Insure the manual file copy completed successfully
				If EXIST "!copytodir!\!file!" ( 
					REM Add the date and passed variables to the vac_ready_files.log file
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // PASS // MANUAL    // SINGLE // !label! // Tor: !file! // Path: !savedir! -to- !copytodir! >> !filelog!
				) else (
					REM Add the date and passed variables to the vac_ready_files.log file
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // FAIL // MANUAL    // SINGLE // !label! // Tor: !file! // Path: !savedir! -to- !copytodir! >> !filelog!		
				)
			) else (
				REM Add the date and passed variables to the vac_ready_files.log file
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // SKIP // UNKNOWN   // SINGLE // !label! // Tor: !file! // [COMPLETED DIRECTORY ALREADY HAS FILES] Path: !copytodir! >> !filelog!
			)
		) else (
			If NOT EXIST "!copytodir!" (
				REM Create the completed directory sub-folder to copy the torrent files to
				MKDIR "!copytodir!" 
				REM copy the source torrent files to the completed directory sub-folder
				COPY "!savedir!" "!copytodir!" 
				REM Insure the manual sub-folder creation and copy completed successfully
				If EXIST !copytodir! ( 
					REM Add the date and passed variables to the vac_ready_files.log file
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // PASS // MANUAL    // FOLDER // !label! // Tor: !file! // Path: !savedir! -to- !copytodir! >> !filelog!
				) else (
					REM Add the date and passed variables to the vac_ready_files.log file
					ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // FAIL // MANUAL    // FOLDER //!label! // Tor: !file! // Path: !savedir! -to- !copytodir! >> !filelog!		
				)
			) else (
				REM Add the date and passed variables to the vac_ready_files.log file
				ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // SKIP // UNKNOWN   // FOLDER // !label! // Tor: !file! // [COMPLETED DIRECTORY ALREADY HAS FILES] Path: !copytodir! >> !filelog!
			)
		)
	) else (
		REM Add the date and passed variables to the vac_ready_files.log file
		ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // PASS // UNKNOWN   //        // !label! // Tor: !file! // [UNKNOWN] Path: !savedir! >> !filelog!
	)
) else (
	REM Add the date and passed variables to the vac_ready_files.log file
	ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // PASS // AUTOMATIC //        // !label! // Tor: !file! // Path: !savedir! >> !filelog!
)

REM PAUSE
REM Add the date and passed variables to the vac_ready_files.log file
REM ECHO [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // !label! // !file! // !savedir! >> !filelog!
REM ECHO **READY** [!date:~4,2!-!date:~7,2!-!date:~10,4! !time:~0,8!] // READY // !label! // !file! // !savedir! >> !filelog!