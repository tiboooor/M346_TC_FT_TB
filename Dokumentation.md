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
  


<a name="anker4"></a>
## 3. Anleitung  
  
  
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
[Testfall 1](install_server.sh)  

**Testfall 2**  
Mit diesem Skript wurde das Vorgehen etwas abgeändert, hier wird zuerst die ID eines bereits bestehenden VPC ausgelesen.  
Danach wird auch die ID eines bereits bestehenden Subnets ausgelesen und mit diesen Angaben 
[Testfall 2](install_server2.sh)
  
  
<a name="anker6"></a>
## 5. Reflexion

