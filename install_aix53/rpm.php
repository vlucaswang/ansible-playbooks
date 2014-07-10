#!/usr/bin/php -q

<?php 

// hack to get socket_strerror working on old systems 
if(!function_exists("socket_strerror")){ 
    function socket_strerror($sh){ 
        if(function_exists("strerror")){ 
            return strerror($sh); 
        } else { 
            return false; 
        } 
    } 
} 

// telnet class 
define ("TELNET_ERROR", 0); 
define ("TELNET_OK", 1); 
define ("TELNET_ASK_CONFIRMATION", 2); 
define ("LIBELLE_CONFIRMATION", "[confirm]"); 

class telnet { 

    var $socket  = NULL; 
    var $host = ""; 
    var $port = "23"; 
    var $timeout=30;
    var $error = ""; 
    var $codeError = ""; 
    var $prompt = "> "; 
    var $log = NULL;  // file handle 
    var $LogDirectory= ""; 
    var $LogFileName = ""; 

    var $test; 

    var $buffer = ""; 

    //------------------------------------------------------------------------ 
    function connect(){ 
        $this->socket = fsockopen($this->host,$this->port, $codeError, $error,$this->timeout); 
        if (!$this->socket){ 
            $this->error = "unable to open a telnet connection: " . socket_strerror($this->socket) . "\n"; 
			$this->codeError=$codeError;
            return TELNET_ERROR; 
        } 

        socket_set_timeout($this->socket,$this->timeout,0); 
        return TELNET_OK; 
    } 

    //------------------------------------------------------------------------ 
    function read_to($chaine){ 
        $NULL = chr(0); 
        $IAC = chr(255); 
        $buf = ''; 

        if (!$this->socket){ 
            $this->error = "telnet socket is not open"; 
            return TELNET_ERROR; 
        } 

        while (1){ 
            $c = $this->getc(); 

            if ($c === false){ 
             // plus de caracteres a lire sur la socket 
                if ($this->contientErreur($buf)){ 
                    return TELNET_ERROR; 
                } 

                $this->error = " Couldn't find the requested : '" . $chaine . "', it was not in the data returned from server : '" . $buf . "'" ; 
                $this->logger($this->error); 
                return TELNET_ERROR; 
            } 

            if ($c == $NULL || $c == "\021"){ 
                continue; 
            } 

            if ($c == $IAC){ 
                // Interpreted As Command 
                $c = $this->getc(); 

                if ($c != $IAC){ 
                    // car le 'vrai' caractere 255 est doublnaour le differencier du IAC 
                    if (! $this->negocierOptionTelnet($c)){ 
                        return TELNET_ERROR; 
                    } else { 
                        continue; 
                    } 
                } 

            } 

            $buf .= $c; 

            // append current char to global buffer 
            $this->buffer .= $c; 

            // indiquer ?'utilisateur de la classe qu'il a une demande de confirmation 
            if (substr($buf,strlen($buf)-strlen(LIBELLE_CONFIRMATION)) == LIBELLE_CONFIRMATION){ 
                $this->logger($this->getDernieresLignes($buf)); 
                return TELNET_ASK_CONFIRMATION; 
            } 

            if ((substr($buf,strlen($buf)-strlen($chaine))) == $chaine){ 
                // on a trouve la chaine attendue 

                $this->logger($this->getDernieresLignes($buf)); 

                if ($this->contientErreur($buf)){ 
                    return TELNET_ERROR; 
                } else { 
                    return TELNET_OK; 
                } 
            } 
        } 
    } 

    //------------------------------------------------------------------------ 
    function getc(){ 
        return fgetc($this->socket); 
    } 

    //------------------------------------------------------------------------ 
    function get_buffer(){ 
        $buf = $this->buffer; 

        // cut last line (is always prompt) 
        $buf = explode("\n", $buf); 
        unset($buf[count($buf)-1]); 
        $buf = join("\n",$buf); 
        return trim($buf); 
    } 

    //------------------------------------------------------------------------ 
    function negocierOptionTelnet($commande){ 
        // on negocie des options minimales 

        $IAC = chr(255); 
        $DONT = chr(254); 
        $DO = chr(253); 
        $WONT = chr(252); 
        $WILL = chr(251); 

        if (($commande == $DO) || ($commande == $DONT)){ 
            $opt = $this->getc(); 
            //echo "wont ".ord($opt)."\n"; 
            fwrite($this->socket,$IAC.$WONT.$opt); 
        } else if (($commande == $WILL) || ($commande == $WONT)) { 
            $opt = fgetc($this->socket); 
            //echo "dont ".ord($opt)."\n"; 
            fwrite($this->socket,$IAC.$DONT.$opt); 
        } else { 
            $this->error = "Error : unknown command ".ord($commande)."\n"; 
            return false; 
        } 

        return true; 
    } 

    //------------------------------------------------------------------------ 
    function write($buffer, $valeurLoggee = "", $ajouterfinLigne = true){ 

        // clear buffer from last command 
        $this->buffer = ""; 

        if (! $this->socket){ 
            $this->error = "telnet socket is not open"; 
            return TELNET_ERROR; 
        } 

        if ($ajouterfinLigne){ 
            $buffer .= "\n"; 
        } 

        if (fwrite($this->socket,$buffer) < 0){ 
            $this->error = "error writing to socket"; 
            return TELNET_ERROR; 
        } 

        if ($valeurLoggee != ""){ 
            // cacher les valeurs confidentielles dans la log (mots de passe...) 
            $buffer = $valeurLoggee . "\n"; 
        } 

        if (! $ajouterfinLigne){ 
            // dans la log (mais pas sur la socket), rajouter tout de meme le caractere de fin de ligne 
            $buffer .= "\n"; 
        } 

        $this->logger("> " .$buffer); 

        return TELNET_OK; 
    } 

    //------------------------------------------------------------------------ 
    function disconnect(){ 
        if ($this->socket){ 
            if (! fclose($this->socket)){ 
                $this->error = "error while closing telnet socket"; 
                return TELNET_ERROR; 
            } 

            $this->socket = NULL; 
        } 

        $this->setLog(false,""); 
        return TELNET_OK; 
    } 

    //------------------------------------------------------------------------ 
    function contientErreur($buf){ 
        $messagesErreurs[] = "nvalid";       // Invalid input, ... 
        $messagesErreurs[] = "o specified";  // No specified atm, ... 
        $messagesErreurs[] = "nknown";       // Unknown profile, ... 
        $messagesErreurs[] = "o such file or directory"; // sauvegarde dans un repertoire inexistant 
        $messagesErreurs[] = "llegal";       // illegal file name, ... 

        foreach ($messagesErreurs as $erreur){ 
            if (strpos ($buf, $erreur) === false) 
                continue; 

                // FdK{4mNsO{O"
                $this->error =  "7~NqFw75;XR;8v4mNs : " . 
                    "<BR><BR>" . $this->getDernieresLignes($buf,"<BR>") . "<BR>"; 

                return true; 
            } 

        return false; 
    } 

    //------------------------------------------------------------------------ 
    function wait_prompt(){ 
        return $this->read_to($this->prompt); 
    } 

    //------------------------------------------------------------------------ 
    function set_prompt($s){ 
        $this->prompt = $s; 
        return TELNET_OK; 
    } 

    //------------------------------------------------------------------------ 
    function set_host($s){ 
        $this->host = $s; 
    } 

    //------------------------------------------------------------------------ 
    function set_port($s){ 
        $this->port = $s; 
    } 
	function set_timeout($s){
		$this->timeout=$s;
	}

    //------------------------------------------------------------------------ 
    function get_last_error(){ 
        return $this->error; 
    } 

    //------------------------------------------------------------------------ 
    function setLog($activerLog, $ServerType){ 

        if ($this->log && $activerLog){ 
            return TELNET_OK; 
        } 

        if ($activerLog){ 
			$this->LogDirectory =  "./log";
            if (! file_exists($this->LogDirectory)){ 
                if (mkdir($this->LogDirectory, 0700) === false){ 
                    $this->error = "D?B<H(O^4mNs#! " .  $this->LogDirectory; 
                    return TELNET_ERROR; 
                } 
            } 


            $this->LogFileName = $ServerType . ".log"; 

            $this->log = fopen($this->LogDirectory . "/" . $this->LogFileName,"a"); 

            if (empty($this->log)){ 
                $this->error = "4r?*HUV>ND<~3v4m#!" . $this->LogFileName; 
                return TELNET_ERROR; 
            } 

            $this->logger("==============================================\r\n"); 
            $this->logger("From adresse IP: " . $this->host . "\r\n"); 
            $this->logger("Connect to server: " . $this->host . ", port: " . $this->port . "\r\n"); 
            $this->logger("Date: " . date("Y-m-d H:i:s") .  "\r\n"); 
            $this->logger("ServerType: " . $ServerType . "\r\n"); 
            $this->logger("----------------------------------------------\r\n"); 
            return TELNET_OK; 

        } else { 
            if ($this->log){ 
                $this->logger("----------------------------------------------\r\n"); 
                $this->logger("end of log file write\r\n"); 

                fflush($this->log); 

                if (! fclose($this->log)){ 
                    $this->error = "9X1UHUV>ND<~3v4m"; 
                    return TELNET_ERROR; 
                } 

                $this->log = NULL; 
            } 

            return TELNET_OK; 
        } 
    } 

    //------------------------------------------------------------------------ 
    function logger($s){ 
        if ($this->log){ 
            fwrite($this->log, $s); 
        } 
    } 

    //------------------------------------------------------------------------ 
    function getDernieresLignes($s, $separateur="\n"){ 
        // une reponse telnet contient (en principe) en premiere ligne l'echo de la commande utilisateur. 
        // cette methode renvoie tout sauf la premiere ligne, afin de ne pas polluer les logs telnet 

        $lignes = explode("\n",$s); 
        $resultat = ""; 
        $premiereLigne = true; 

        while(list($key, $data) = each($lignes)){ 
            if ($premiereLigne){ 
                $premiereLigne = false; 
            } else { 
                if ($data != ""){ 
                    $resultat .= $data . $separateur; 
                } 
            } 
        } 

        $resultat == substr($resultat,strlen($resultat)-1); // enlever le dernier caractere de fin de ligne 

        return $resultat; 
    } 

    //------------------------------------------------------------------------ 
}   //    end of telnet.class.php

// test simple
	
	if ( count($argv)!=4 ) {
		echo "Usage: $argv[0] remotehost username password\n";
		exit;
	}
	$telnet=new telnet;
	$telnet->setLog(1,"telnet.log");
	$telnet->set_host($argv[1]);
	$telnet->connect();
	$telnet->set_prompt("ogin: ");                                     $telnet->wait_prompt();
	$telnet->write($argv[2]);
	$telnet->set_prompt("assword: ");                                  $telnet->wait_prompt();
	$telnet->write($argv[3]);
	$telnet->set_prompt("> ");                                         $telnet->wait_prompt();
	$telnet->write("cd /tmp/ansible");                                 $telnet->wait_prompt();
	$telnet->write("ls -l *rpm ");                                     $telnet->wait_prompt();
	$telnet->write("rpm -ivh libgcc-4.8.2-1.aix5.3.ppc.rpm");          $telnet->wait_prompt();
	$telnet->write("rpm -ivh libffi-3.0.13-1.aix5.1.ppc.rpm");         $telnet->wait_prompt();
	$telnet->write("rpm -ivh python-libs-2.6.8-1.aix5.1.ppc.rpm");     $telnet->wait_prompt();
	$telnet->write("rpm -ivh gettext-0.17-1.aix5.1.ppc.rpm --nodeps"); $telnet->wait_prompt();
	$telnet->write("rpm -ivh libiconv-1.14-2.aix5.1.ppc.rpm");     $telnet->wait_prompt();
	$telnet->write("rpm -ivh glib2-2.38.2-1.aix5.1.ppc.rpm ");     $telnet->wait_prompt();
	$telnet->write("rpm -ivh bash-4.2-12.aix5.1.ppc.rpm");         $telnet->wait_prompt();
	$telnet->write("rpm -ivh info-5.1-2.aix5.1.ppc.rpm");          $telnet->wait_prompt();
	$telnet->write("rpm -ivh readline-6.2-5.aix5.1.ppc.rpm");      $telnet->wait_prompt();
	$telnet->write("rpm -ivh libpng-1.6.7-1.aix5.1.ppc.rpm ");     $telnet->wait_prompt();
	$telnet->write("rpm -ivh freetype2-2.5.2-1.aix5.1.ppc.rpm");   $telnet->wait_prompt();
	$telnet->write("rpm -ivh fontconfig-2.10.2-1.aix5.1.ppc.rpm"); $telnet->wait_prompt();
	$telnet->write("rpm -ivh libXrender-0.9.8-1.aix5.1.ppc.rpm --nodeps");  $telnet->wait_prompt();
	$telnet->write("rpm -ivh libXft-2.3.1-1.aix5.1.ppc.rpm --nodeps");      $telnet->wait_prompt();
	$telnet->write("rpm -ivh tk-8.5.15-1.aix5.1.ppc.rpm --nodeps");        $telnet->wait_prompt();
	$telnet->write("rpm -ivh libstdc++-4.8.2-1.aix5.3.ppc.rpm");        $telnet->wait_prompt();
	$telnet->write("rpm -ivh gmp-5.1.3-1.aix5.1.ppc.rpm");        $telnet->wait_prompt();
	$telnet->write("rpm -ivh sqlite-3.8.1-1.aix5.1.ppc.rpm");     $telnet->wait_prompt();
	$telnet->write("rpm -ivh python-2.6.8-1.aix5.1.ppc.rpm");     $telnet->wait_prompt();
	$telnet->write("rpm -ivh expect-5.45-1.aix5.1.ppc.rpm");      $telnet->wait_prompt();

	$telnet->write("exit");
	$telnet->disconnect(); 

	echo "rpm install Okey, please view log/telnet.log ";
?> 
