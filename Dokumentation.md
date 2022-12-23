# Dokumentation CMS-Cloudprojekt
![image](https://user-images.githubusercontent.com/114081005/207621040-e34b98ed-5b67-4dfd-a21b-21b2f301c048.png)

In diesem Markdown wird das gesamte Projekt dokumentiert und beschrieben. In den ersten Kapitel kommen Informationen über das Projekt vor, gemeint damit sind die Wahl des Conten Management Systems und weiteres. Danach folgen die beschriebene Konfiguration und das erstellen der AWS-Instanzen und später findet man noch Testfälle auf welche während des Projekt ausgeführt worden sind.

### Inhaltsverzeichnis


[**1. Projektinformationen**](#anker)  
[**1.1 CMS**](#anker1)  
[**1.2 Aufgaben und Zuständigkeit**](#anker2)  
[**2. Installation und Konfiguration**](#anker3)  
[**3. Anleitung**](#anker4)  
[**4. Testfälle**](#anker5)  
[**5. Reflexion**](#anker6)
<a name="anker"></a>
## 1. Projektinformationen
In diesem Abschnitt wird die Wahl des CMS beschrieben und die verschiedenen Aufgaben aufgezählt und wer Zuständigkeit für was hat.  

<a name="anker1"></a>
### 1.1 CMS  
CMS oder auch Content-Management-System werden im Webhosting verwendet, dabei handelt es sich um eine Anwendung mit welcher die Erstellung und bearbeitung von Webseiten.  
Wir haben uns für Wordpress entschieden, da wir bereits einmal mit diesem CMS gearbeitet haben und uns schon ein wenig auskennen. Zudem ist Wordpress gratis, wenn man selber hostet.

<a name="anker2"></a>
### 1.2 Aufgaben und Zuständigkeit
Für das Projekt muss ein Content-Management-System auf einer AWS-Instanz erstellen, zudem muss die Datenbank in einer anderen Instanz vorhanden sein. Zwischendurch sollten Tests ausgeführt werden und sauber in der Dokumentation sein. Das Projekt sollte schlussendlich automatisiert werden. Die Aufgaben haben wir untereinander so verteilt.

<a name="anker3"></a>
## 2. Installation und Konfiguration
[Finale Version des Scriptes](install_server3.sh)  
Ab hier wird angenommen, dass dieser Code schlussendlich auf einer Ubuntmaschine läuft.  
  
### Code Linie für Linie erklärt  
```  
aws ec2 create-key-pair --key-name cms_key --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/cms_key.pem  
``` 
Hier wird ein SSH-Key-Pair erstellt mit dem Key-Type RSA, dieser Key namens "cms_key" wird dann auch noch in eine Datei geschrieben,um von der Ubuntumaschine SSH-Verbindungen aufbauen zu können.  
  
```  
aws ec2 create-security-group --group-name sec-group-cms --description "SSH and HTTP and 3306 and -1"
```  
Diese Linie erstellt eine Security-Group mit dem Namen "sec-group-cms".  
  
```  
sec_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=sec-group-cms" --query 'SecurityGroups[*].{ID:GroupId}' --output text)
```  
Hier wird die ID der vorher erstellten Security-Group in eine Variabel geschrieben. Es filtert die Security-Groups nach dem Namen und liest mit dem Query die ID aus.  
  
```  
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 3306 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol icmp --port -1 --cidr 0.0.0.0/0
```  
Hier werden die Ports autorisiert auf die Security-Group. Diese wird mit der Variabel angegeben.
  
``` 
mkdir ~/ec2cmsdbserver
cd ~/ec2cmsdbserver
```  
Hier wird auf der Ubuntumaschine ein Verzeichnis angelegt und auch in dieses gewechselt. Das Verzeichnis dient später für die Ablage der Inital Datei des Datenbankservers.  
  
```  
touch initial.txt
```  
Inital Datei wird erstellt.  
  
```  
cat > initial.txt << LAH
#!/bin/bash

sudo apt update
sudo apt install -y mariadb-server
sudo apt install -y mariadb-client
sudo systemctl start mariadb.service
sudo sed -i "s/bind-address            = 127.0.0.1/#bind-address            = 127.0.0.1/" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb.service
sudo touch commands.sql
sudo chmod 777 commands.sql
sudo cat > commands.sql << WHAM
DROP USER IF EXISTS 'wordpressusr'@'%';
FLUSH PRIVILEGES;
CREATE USER 'wordpressusr'@'%' IDENTIFIED BY 'pacozazi99';
DROP DATABASE IF EXISTS wordpress;
CREATE DATABASE wordpress;
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressusr'@'%';
FLUSH PRIVILEGES;
WHAM
sudo mysql < commands.sql
LAH
```  
Hier wird die Inital Datei befüllt, dazu wird der Command cat verwendet zusammen mit <<. Das LAH ist einfach ein Anfang, das Ende muss einfach gleich heissen.  
In der Datei wird zuerst ein Update des Servers ausgelöst und dann MariaDB-Server und MariaDB-Client installiert. Mit "sudo systemctl start mariadb.service" wird sichergestellt, dass der Dienst nach der Installation wirklich läuft.  
Damit MariaDB auch von anderen Servern erreichbar ist muss in der "50-server.cnf" Datei unter "/etc/mysql/mariadb.conf.d/" die Bind-Address auskomentiert werden. Hier mit dem sed Command.  
Maradb wird neu gestartet.  
Eine Datei für die Benötigten SQL Commands wird erstellt und die Berechtigungen geändert.  
Die Befehle werden auf gleiche Weise wie bei der Initial Datei in die Datei geschieben nur mit dem Anfang und Ende WHAM.  
Die SQL Befehle löschen und erstellen einen User namens "wordpressusr". Das Löschen ist nötig, weil man möglicherweise auf einen Bug treffen kann der das Erstellen sonst nicht ermöglicht.  
Es erstellt eine Datenbank "wordpress" und gibt dem User "wordpressusr" volle Recht darauf.  
Diese SQL Datei wird dann mit dem Befehl "sudo mysql < commands.sql" ausgeführt.  
  
  
Da nun alles für die EC2 Instanz des Datenbakservers vorbereitet ist, kann dieser nun installiert werden.  
```  
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'
```  
Hier werden alle Vorherigen Dateien und Variabeln verwendet um die Angaben des Servers auszufüllen. Der Server erhält den Namestag: "cms_dataserver".  

```  
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=cms_dataserver" --query 'Reservations[*].Instances[*].InstanceId' --output text)
``` 
Die Instance ID wird ausgelesen und in eine Variabel geschrieben. Wieder mit einem Filter auf den Namen und einem Query nach der ID.  
  
``` 
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
```  
Die öffentliche IP-Adresse wird in eine Variabel geschrieben, nach der richtigen Instance wird mithilfe der Variabel INSTANCE_ID gefiltert. Der Query gibt dann nur die IP-Adresse aus.  
  
``` 
mkdir ~/ec2cmswebserver  
cd ~/ec2cmswebserver
``` 
Hier wird als Vorbereitung für den Webserver ein Ordner erstellt und dahin gewechselt. Der Ordner ist wieder für die aufbewahrung der Inital Datei.  
  
```
touch initial.txt
```  
Inital Datei wird erstellt.  
  
```  
table_prefix='$table_prefix'
``` 
Hier wird der Wert $table_prefix in die Variabel table_prefix geschrieben. Das ist so nötig, weil später eine Konfigurationsdatei erstellt wird die von sich aus diese Variabel gesetzt hat. Wenn man sie hier nicht deklariert, wird sie in der Datei nicht geschrieben.  
  
``` 
cat > initial.txt << END 
#!/bin/bash

sudo apt update
sudo apt install -y apache2

sudo apt install php php-mysql -y
sudo apt install mysql-client -y

wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
sudo cp -R wordpress /var/www/
sudo chown -R www-data:www-data /var/www/wordpress/
sudo chmod -R 755 /var/www/wordpress/
sudo mkdir /var/www/wordpress/wp-content/uploads
sudo chown -R www-data:www-data /var/www/wordpress/wp-content/uploads/
table_prefix='$table_prefix'

cd /var/www/wordpress
sudo touch wp-config.php
sudo cat > wp-config.php << EOF  
```  
Die Inital Datei des Webservers wird befüllt.  
Der Server macht ein Update und installiert Apache. Für das CMS Wordpress muss noch php und php-mysql installiert werden. Der mysql-client wird theoretisch nicht benötigt.  
Danach wird die neuste Version von Wordpress heruntergeladen und mit tar extrahiert. Die Dateien werden dann in das Verzeichnis /var/www verschoben.  
Hier werden die Berechtigungen angepasst und benötigte Ordner erstellt.  
Auch hier ist die Variabel table_prefix nochmals deklariert, dass sie dann auch richtig in die nachfolgend erstellte wp-config Datei geschrieben wird.  
Diese wp-config.php Datei wird erstellt und dann mit Inhalt befüllt.  
In der wp-config sind nur wenige Linien relevant:  
```  
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'wordpressusr' );

/** Database password */
define( 'DB_PASSWORD', 'pacozazi99' );

/** Database hostname */
define( 'DB_HOST', '$PUBLIC_IP' );  
``` 
Hier werden die Angaben von oben direkt eingetragen. Der Hostname der Datenbank ist die öffentliche IP-Adresse und wird mit der Variabel geschrieben.  
In dieser Datei werden auch "Authentication unique keys and salts" eingetragen, diese können mit dem Link in der Beschreibung des Abschnittes generiert werden.  
  
```  
sudo chmod 755 wp-config.php
cd /etc/apache2/sites-available
sudo touch wordpress.conf
sudo chmod 666 wordpress.conf
sudo cat > wordpress.conf << FOO
<VirtualHost *:80>
        DocumentRoot /var/www/wordpress
</VirtualHost>
FOO
sudo a2ensite wordpress.conf
sudo a2dissite 000-default.conf
sudo systemctl restart apache2
END
```  
Am Ende der inital Datei des Webservers wird die wp-config Datei noch ausführbar gemacht.  
Damit die Wordpress Seite direkt aufgerufen wird, erstellt man im /etc/apache2/sites-available Verzeichnis eine neue conf Datei.  
Darin spezifiziert man wo die Index Datei ist. Hier ist es im Verzeichnis /var/www/wordpress.  
Im Titel deklariert man auch über welchen Port die Adresse aufgerufen werden kann.  
Diese neue conf Datei wirt mit a2ensite aktiviert und die alte mit a2dissite deaktiviert. Nach diesen anpassungen muss der Apache Dienst neu gestartet werden.  
  
```  
aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_webserver}]'
```  
Die ganze Vorbeitung wird nun Verwendet um die Instanz für den Webserver zu erstellen. Diese Instanz wird gleich wie die Instanz des Datenbankservers erstellt aber mit dem Namen "cms_webserver".  
  
  ```  
  chmod 600 ~/.ssh/cms_key.pem  
  ```  
  Als aller letztes werden die Berechtigungen für dem Key angepasst, so dass er verwendet werden kann.  
    
   

<a name="anker4"></a>
## 3. Anleitung  
### 1. Schritt  
Bevor das Skript "install_server3.sh" auf einer Ubuntumaschine ausgeführt werden kann müssen einige Sachen überprüft werden:  
- [X] Unter ~/.ssh hat es keinen Key der "cms_key.pem" heisst.  
- [X] Unter ~/ hat es keine Ordner die "ec2cmsdbserver" oder "ec2cmswebserver" heissen.  
- [X] Auf AWS hat es keine Instances die "cms_dataserver" oder "cms_webserver" heissen.  
- [X] Auf AWS hat es keine Security-Group die "sec-group-cms" heisst.  
- [X] Auf AWS hat es kein Key-Pair das "cms_key" heisst.  
- [X] Die Ubuntumaschine muss eine Verbindung zu AWS haben.  
- [X] Das Skript muss noch ausführbar gemacht werden.  
  
### 2. Schritt
Skript mit  
  
    ./install_server3.sh  
  
auf der Ubuntumaschine ausführen.  
Beim Ausführen sollten keine Fehler auftauchen.  
  
### 3. Schritt  
In der AWS Management Console überprüfen, das die beiden Server starten.  
Hier bitte etwas Zeit geben (ca. 3 min), im Hintergrund wird die Datenbank eingerichtet und Wordpress installiert.  
  
### 4. Schritt  
Die Öffentliche IP-Adresse des "cms_webserver" als http://ip-adresse eingeben. Ihr CMS geniessen.  
Die Angabe der Sprache und die Erstellung der Seite mit Admin Login gehören schon zum Aufbau des CMS.  
  
### 5. Anpassungen bei Neustart eines Servers  
Wenn der Server "cms_dataserver" neu gestartet wird, ändert sich seine IP-Adresse und der Webserver wird eine Fehlermeldung anzeigen.  
Um die Webseite wieder richtig einzustellen muss folgendes gemacht werden:  
1. Entweder über die AWS Management Console oder über eine SSH verbindung mit "cms_key.pem" eine Verbindung mit dem "cms_webserver" aufbauen.  
2. Ins Verzeichnis /var/www/wordpress wechseln mit:  
  
```  
cd /var/www/wordpress
```  
  
3. Die Datei "wp-config.php" mit dem bevorzugten Consoleneditor öffnen. Hier mit nano:  
  
```  
sudo nano wp-config.php  
```
  
4. In der Linie:  

```  
/** Database hostname */  
define( 'DB_HOST', '9.240.211.19' );  
```
  
Die alte IP-Adresse zur neuen öffentlichen IP-Adresse des "cms_dataserver" ändern.  
5. Die Änderungen in nano mit CTRL+O und CTRL+X speichern und schliessen.  
6. Es empfiehlt sich mit:  
  
    sudo systemctl restart apache2  
  
den Apache Dienst neu zu starten.  
5. Die Webseite ist nun wieder mit der öffentlichen IP-Adresse des Webservers erreichbar.  
  
### 6. Löschen aller Ressourcen  
Hier eine Liste aller Objekte die in diesem Prozess erstellt worden sind:  
Auf AWS:  
1. Instanz "cms_webserver"  
2. Instanz "cms_dataserver"  
3. Key-Pair "cms_key"  
4. Security-Group "sec-group-cms"  
Auf Ubuntumaschine:  
1. unter ~/ einen Order namens "ec2cmsdbserver"  
2. unter ~/ einen Order namens "ec2cmswebserver"  
3. unter ~/.ssh einen Key namens "cms_key.pem"  
  
Diese Objekte können alle ohne Problem gelöscht werden 
  
<a name="anker5"></a>
## 4. Testfälle  
**Testfall 1** 
  
Dieses Skript wurde 2 Mal überarbeitet. Es ist die erste Version und ich habe mich stark an einer Aufgabe von Unterricht gehalten.  
Das Skript hat in der jetztigen Version alles sauber erstellt. Nur der Zugriff auf die Server hat nicht funktioniert.  
Versuchter Zugriff mit Console direkt in AWS:
![image](https://github.com/tiboooor/M346_TC_FT_TB/blob/7afb3e8963bb6e363c1fda1e4b7b16397e31b264/Bilder/Failed_connection.PNG)  
Versuchter Zugriff mit SSH über Ubuntu Maschiene:  
![image](https://github.com/tiboooor/M346_TC_FT_TB/blob/72f3841168755255a6aa0e6734fc782a7d7d40b4/Bilder/ssh_connection_refused.PNG)  
Dieser Fehler kann verschiedene Ursachen haben. Einer davon ist, dass das Port öffnen in der Security Group nicht richtig gezogen hat.  
Der Port wurde aber geöffnet und die richtige Security Group dem Server zugeteilt worden:  
  
    aws ec2 create-security-group --group-name sec-group-cms --vpc-id $vpc_id --description "SSH and HTTP and 3306"  
    sec_id=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=sec-group-cms" --query 'SecurityGroups[*].{ID:GroupId}' --output text)  
    aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 22 --cidr 0.0.0.0/0  
    aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --associate-public-ip-address --private-ip-address 10.0.1.20 --subnet-id $subnet_id --security-group-ids $sec_id --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'  
  
Eine andere Ursache könnte eine Falsche konfiguration der VPC (Virtual Private Cloud) im zusammenhang mit IGW (Internet Gateway) und NACL (Network Access Control List) sein.  
Hier ist zu beachten, dass beim schreiben dieses Skripts einfach Angaben aus der Aufgabe des Unterrichts verwendet wurden. Den ganz genauen Zusammenhang zwischen all diesen Teilen wurde nicht wirklich verstanden.  
Weil kein richtiger Fehlerpunkt identifiziert werden konnte, wurde ein neues 2. Skript geschrieben.  
[Script zu Testfall 1](install_server.sh)  
  
**Testfall 2**  
  
Mit diesem Skript wurde das Vorgehen etwas abgeändert, hier wird zuerst die ID eines bereits bestehenden VPC ausgelesen.  
Danach wird auch die ID eines bereits bestehenden Subnets ausgelesen und mit diesen Angaben die Security Group und die Instances erstellt.  
Hier war das Problem, dass ich der Security Group nicht das Subnetz zuteilen konnte und so die Konfiguration nicht angewendet wurde.  
Beim ausführen des Skripts sind schon Fehler aufgetaucht, da es bei der VPC Id schon Problemme gibt.  
![image](https://github.com/tiboooor/M346_TC_FT_TB/blob/3f30741ac841b9c51327428074b1cc027752eea2/Bilder/Unknown_Option_vpc.PNG)  
Dieser Fehler bezieht sich ziemlich sicher auf:  
  
    aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name cms_key --vpc-id $vpc_id --subnet-id $SUBNET_ID --security-groups cms-sec-group --private-ip-address 172.31.0.100 --iam-instance-profile Name=LabInstanceProfile --user-data file://initial.txt --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cms_dataserver}]'  
  
Die Erstellung des Servers wird nämlich nicht ausgeführt.  
Nach einigem ausprobieren wurde entschieden ein neues Skript zu schreiben.  
[Script zu Testfall 2](install_server2.sh)  
  
  
<a name="anker6"></a>
## 5. Reflexion  
**Tibor Blasko**  
Das Projekt an sich, bzw. das Konzept ist sehr interessant. Die Themen sind ebenfalls alle spannend. Wir haben auch bereits im Unterricht mit AWS CLI gearbeitet, womit wir auch beim Projekt gearbeitet haben. Jedoch kam das Projekt viel zu kurzfristig und war meiner Meinung nach für diese Zeitspanne vom Umfang her zu komplex. Das hat beim SQL-Projekt besser funktioniert.  
  
**Franziska Tobler**  
Dieses Projkt hat mich richtig herausgefordert. Ich habe den Teil des Code schreibens übernommen und das hat mir Spass gemacht.  
Angefangen hat das Projekt ziemlich harmlos, ich dachte noch, dass wird einfach, da wir im Unterricht schon ein paar AWS CLI Commands gebraucht haben.  
Oh habe ich mich geirrt, ich habe sehr viel Zeit investiert nur um kleine Fehler zu beheben. Der Grundaufbau des Skrips habe ich 4mal überarbeitet, nur um dann den grössten Teil wieder zu löschen..  
Zum Glück konnte ich in meinem Betrieb den Code gegenlesen lassen und so sind einige Fehler behoben worden.  
Das Projekt im ganzen, für mich hat die Vorbereitung für das Projekt nicht gereicht das Projekt ohne Probleme zu erledigen.  
Was mir gefehlt hat, waren Erklärungen bezüglich dem Netzwerkaufbau in AWS, wie das ganze mit Serverregionen etc. funktioniert.  


**Tiziano Corbetti**
