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
Für das Projekt muss ein Content-Management-System auf einer AWS-instanz erstellen, zudem muss die Datenbank in einer anderen Instanz vorhanden sein. Zwischendurch sollten Tests ausgeführt werden und sauber in der Dokumentation sein. Das Projekt sollte schlussendlich automatisiert werden. Die Aufgaben haben wir untereinander so verteilt.

<a name="anker3"></a>
## 2. Installation und Konfiguration
[Finale Version des Scriptes](install_server3.sh) 
  


<a name="anker4"></a>
## 3. Anleitung  
  
  
<a name="anker5"></a>
## 4. Testfälle  
**Testfall 1**  
Dieses Skript wurde 2 Mal überarbeitet. Es ist die erste Version und ich habe mich stark an einer Aufgabe von Unterricht gehalten.  
  
        aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 22 --cidr 0.0.0.0/0  
  
  
[Testfall 1](install_server.sh)

[Testfall 2](install_server2.sh)
  
  
<a name="anker6"></a>
## 5. Reflexion

