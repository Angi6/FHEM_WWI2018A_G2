//JavaScript-Datei für stockMain.html

//Variable die benötigt wird damit Eventhandler nicht doppelt ausgeführt werden
let x = 0;

//Funktion zum Laden der Aktien
function loadStocks() {
    //speichern der Referenz auf das Element mit der ID "selectOptionPerformance" in die Variable selectPerformanceWKN
    let selectPerformanceWKN = document.getElementById("selectOptionPerformance");
    //speichern der Referenz auf das Element mit der ID "selectOptionNotifyWKN" in die Variable selectNotifyWKN
    let selectNotifyWKN = document.getElementById("selectOptionNotifyWKN");
    //Referenz auf die Aktientabelle in die Variable stockTable speichern
    let stockTable = document.getElementById("stockTable");
    //variable selectChange speichert ob der Benutzer Kursänderungen relativ oder Absolut gespeichert haben möchte
    let selectChange = document.getElementById("selectOptionChange").value;

    //Perl Funktion "getStocks()" aus FHEM aufrufen und return Wert in die Variable stockData speichern
    //stockData enthält die Gerätnamen der Aktiengeraäte, diese sind gleichzeitig die WKN-Nummern
    ftui.sendFhemCommand('{getStocks()}').done(function (stockData) {
        //Aktientabelle leeren
        $("#stockTable").empty();
        //Dropdownmenü mit den Aktiennamen im Bereich für die graphische Darstellung leeren
        $('#selectOptionPerformance').find('option').remove().end();
        //Dropdownmenü mit den Aktiennamen im Bereich für die Benachrichtigungen leeren
        $('#selectOptionNotifyWKN').find('option').remove().end();

        //aus stockData ein Array mit dem namen stocks machen
        let stocks = JSON.parse(stockData);

        //Iteration durch stocks
        for (let i = 0; i < stocks.length; i++) {
            //Wert des Readings Name der jeweiligen Aktien, wird gespeichert in die Variable nameData
            //Reading Name enthält den Namen der Aktie, z.B. SAP
            ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Name","undefined")}').done(function (nameData) {
                //Wert des Readings Price der jeweiligen Aktien, wird gespeichert in die Variable priceData
                //Reading Price enthält den Wert einer Aktie
                ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Price","undefined")}').done(function (priceData) {
                    //Wert des Readings RelativeChange oder AbsolutChange der jeweiligen Aktien, wird gespeichert in die Variable changeData
                    //Welches Reading ausgelesen wird entscheidet sich durch den Benutzer
                    //Reading changeRelative enthält die relative Kursänderung, changeAbsolut die absolute Kursänderung
                    ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "' + selectChange + '","undefined")}').done(function (changeData) {

                        //Neue Tabellenreihe in der Aktientabelle einfügen
                        let stockRow = stockTable.insertRow(-1);

                        //Erstellen der Zellen in der neuen Tabellenreihe
                        let stockCell = stockRow.insertCell(0);
                        let wknCell = stockRow.insertCell(1);
                        let valueCell = stockRow.insertCell(2);
                        let changeCell = stockRow.insertCell(3);
                        let buttonCell = stockRow.insertCell(4);

                        //Erstellen des <button> Elements mit der onclick-Funktion deleteStock(WKN)
                        let deleteButton = document.createElement("button");
                        deleteButton.setAttribute("onclick", "deleteStock(\"" + stocks[i] + "\")");
                        deleteButton.innerHTML = "Aktie loeschen";
                        deleteButton.setAttribute("class", "buttonCell");

                        //Zellen mit Inhalt befüllen
                        stockCell.innerHTML = nameData;
                        wknCell.innerHTML = stocks[i];
                        valueCell.innerHTML = priceData;
                        changeCell.innerHTML = changeData;
                        buttonCell.appendChild(deleteButton);

                        //<option> Element für das Dropdown-Menü für die Auswahl der Aktie bei der graphischen Darstellung
                        let optionPerformanceWKN = document.createElement("option");
                        optionPerformanceWKN.setAttribute("value", stocks[i]);
                        //optionPerformanceWKN.setAttribute("value", i);
                        optionPerformanceWKN.innerHTML = nameData;

                        //Erstelltes <option> Element für das Dropdown-Menü bei den Benachrichtiungen klone
                        let optionNotifyWKN = optionPerformanceWKN.cloneNode(true);

                        //<option> Elemente den Dropdown-Menüs hinzufügen
                        selectPerformanceWKN.add(optionPerformanceWKN);
                        selectNotifyWKN.add(optionNotifyWKN);

                    });
                });
            });
        }
    });
}

//Funktion um eine neue Aktie hinzuzufügen
function addStock() {
    //Variable wkn speichert die vom Benutzer eingegebene WKN-Nummer
    let wkn = document.getElementById("sendWKN").children[0].value;
    //Prüfung ob Benutzer etwas eingegeben hat
    if (wkn != "") {
        //Perl-Funktion addStock("wkn") in FHEM aufrufen
        let cmd = '{addStock("' + wkn + '")}'
        ftui.sendFhemCommand(cmd).done(function () {
            //loadStocks() aufrufen
            setTimeout(() => {
                loadStocks()
            }, 2000);
        });
    }
    //Input feld leeren
    document.getElementById("sendWKN").children[0].value = "";
}


//Funktion um Aktie zu löschen, benötigt als Parameter die WKN-Nummer der zu löschenden Aktie
function deleteStock(wkn) {
    //Perl-Funktion deleteStock("wkn") in FHEM aufrufen
    let cmd = '{deleteStock("' + wkn + '")}';
    ftui.sendFhemCommand(cmd).done(function () {
        //Aufrufen von loadStocks() und loadNotify()
        loadStocks();
        loadNotify();
    });

}

//Funktion um die graphische Darstellung anzuzeigen
function loadChart() {
    //Referenz auf das Element mit der ID "stockChart"  in die Variable oldCanvas
    //Element enthält den Graphen
    let oldCanvas = document.getElementById("stockChart");
    //Element auf das oldCanvas referenziert klonen und in die Variable canvas speichern
    //Kindelemente werden nicht mitgeklont
    let canvas = oldCanvas.cloneNode(false);
    //Element auf das oldCanvas referenziert löschen, damit wird die alte Graphik gelöscht
    oldCanvas.remove();

    //geklontes Element als Kindelement an das Element mit der ID "canvasDiv" anfügen
    document.getElementById("canvasDiv").appendChild(canvas);

    //Folgender Abschnitt, ermittelt bis zu welchem Zeitpunkt die Logeinträge benötigt werden
    //Dies ist abhängig von der Auswahl des Benutzers
    let timeChosen = document.getElementById("selectOptionTimes").value;
    let datetime;
    let date;
    let month;
    let year;
    let hours;
    let minutes;
    let seconds;
    let dateString;

    switch (timeChosen) {
        case "1":
            datetime = new Date()
            datetime.setDate(datetime.getDate() - 1)
            date = ("0" + datetime.getDate()).slice(-2);
            month = ("0" + (datetime.getMonth() + 1)).slice(-2);
            year = datetime.getFullYear();
            hours = ("0" + (datetime.getHours() + 1)).slice(-2);
            minutes = ("0" + (datetime.getMinutes() + 1)).slice(-2)
            seconds = ("0" + (datetime.getSeconds() + 1)).slice(-2)
            dateString = year + "-" + month + "-" + date + "_" + hours + ":" + minutes + ":" + seconds;
            break;

        case "2":
            datetime = new Date()
            datetime.setDate(datetime.getDate() - 7)
            date = ("0" + datetime.getDate()).slice(-2);
            month = ("0" + (datetime.getMonth() + 1)).slice(-2);
            year = datetime.getFullYear();
            hours = ("0" + (datetime.getHours() + 1)).slice(-2);
            minutes = ("0" + (datetime.getMinutes() + 1)).slice(-2)
            seconds = ("0" + (datetime.getSeconds() + 1)).slice(-2)
            dateString = year + "-" + month + "-" + date + "_" + hours + ":" + minutes + ":" + seconds;
            break;

        default:
            dateString = "2016-10-01_08:00:00"
            break;
    }

    //Variable wkn speichert die WKN-Nummer der anzuzeigenden Aktie
    let wkn = document.getElementById("selectOptionPerformance").value

    //Benötigte Logs der Aktie aus FHEM holen, und in die Variable logs speichern
    ftui.sendFhemCommand('{getLogs("' + wkn + '", "' + dateString + '")}').done(function (logs) {

        //Aus logs ein zweidimensionales Array machen, welche die Zeitpunkte mit den Kursen matched
        let logFileArray = logs.split("\n");
        let logRowArray = new Array();

        for (let i = 0; i < logFileArray.length; i++) {
            logFileArray[i] = logFileArray[i].replaceAll(".", "");
            logFileArray[i] = logFileArray[i].replaceAll(",", ".");
            logRowArray[i] = logFileArray[i].split(" ");
        }

        //Aus dem zweidimensionales Array zwei eindimensionale Arrays erstellen
        //Werte und Zeitpunkte die sich auf das Wochenende beziehen oder zwischen 22 Uhr und 8 Uhr angelegt wurden werden ignoriert
        let values = new Array();
        let dates = new Array();
        let z = 0;
        for (let i = 0; i < logFileArray.length; i++) {
            logRowArray[i][0] = logRowArray[i][0].replace("_", " ");
            let dt = new Date(logRowArray[i][0]);
            if ((dt.getDay() != 6 && dt.getDay() != 0) && (dt.getHours() >= 8 && dt.getHours() < 22)) {
                values[z] = parseFloat(logRowArray[i][3]);
                dates[z] = logRowArray[i][0];
                z++;
            }
        }

        //Graphik mit Hilfe von Chart.js erstellen
        let chart = new Chart(canvas, {
            //Typ: Linechart
            type: 'line',
            data: {
                //Zeitpunkte befinden sich auf der x-Achse
                labels: dates,
                datasets: [{
                    //Kurswerte befinden sich auf der y-Achse
                    data: values,
                    label: "Aktienkurs",
                    //Farbe blau
                    borderColor: "#3e95cd",
                    //Keine Füllung
                    fill: false
                },
                ]
            },
            options: {
                elements: {
                    line: {
                        //Verbindung zwischen zwei Punkten verläuft immer geradlinig
                        tension: 0
                    }
                },
                title: {
                    //Überschrift: Kursverlauf
                    display: true,
                    text: 'Kursverlauf'
                },
                scales: {
                    //x-Achse wird nicht angezeigt, da zu viele Zeitpunkte vorhanden sind
                    xAxes: [{
                        display: false //this will remove all the x-axis grid lines
                    }]
                }
            }
        });
    });
}

//Funktion um die Benachrichtigungstabelle zu laden
function loadNotify() {
    //Referenz auf die Benachrichtigungstabelle in die Variable notifyTable speichern
    let notifyTable = document.getElementById("notifyTable")

    //Benachrichtigungstabelle leeren
    $("#notifyTable").empty();

    //Aktien aus FHEM auslesen
    ftui.sendFhemCommand('{getStocks()}').done(function (stockData) {
        let stocks = JSON.parse(stockData);

        for (let i = 0; i < stocks.length; i++) {
            //Benötigte Attribute und Readings auslesen
            ftui.sendFhemCommand('{AttrVal("' + stocks[i].toUpperCase() + '", "ChangePercent","undefined")}').done(function (percentageData) {
                ftui.sendFhemCommand('{AttrVal("' + stocks[i].toUpperCase() + '", "ChangeTime","undefined")}').done(function (timeData) {
                    //Prüfen ob timeData existiert, sonst wird Funktion nicht ausgegührt
                    if (!isNaN(timeData)) {
                        ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Name","undefined")}').done(function (nameData) {
                            ftui.sendFhemCommand('{AttrVal("' + stocks[i].toUpperCase() + '", "Contacts","undefined")}').done(function (usernameData) {
                                //aus dem erhaltenen String mit den Usernames ein Array erstellen
                                let usernames = usernameData.split(",");

                                ftui.sendFhemCommand('{getContactsTele()}').done(function (contactData) {

                                    let userContacts = JSON.parse(contactData);
                                    let contactArray = [];

                                    for (let j in userContacts) {
                                        contactArray.push([j, userContacts [j]]);
                                    }

                                    //Neue Tabelleneihe erstellen
                                    let tableRow = notifyTable.insertRow(-1);

                                    //Zellen der Tabellenreihe erstellen
                                    let accountCell = tableRow.insertCell(0);
                                    let stockCell = tableRow.insertCell(1);
                                    let timeCell = tableRow.insertCell(2);
                                    let percentageCell = tableRow.insertCell(3);
                                    let buttonCell = tableRow.insertCell(4);

                                    //Knopf erstellen, mit der die Benachrichtigungen entfernt werden können
                                    let deleteButton = document.createElement("button");
                                    deleteButton.setAttribute("onclick", "deleteNotify(\"" + stocks[i] + "\")");
                                    deleteButton.setAttribute("class", "buttonCell");
                                    deleteButton.innerHTML = "Benachrichtigung loeschen";

                                    //selectedContacts enthält die Namen der Kontakte
                                    let selectedContacts = "";
                                    
                                    //selectedContacts befüllen
                                    for (let k = 0; k < usernames.length; k++) {
                                        usernames[k] = usernames[k].replaceAll("\n", "")
                                        for (let j = 0; j < contactArray.length; j++) {
                                            if (usernames[k] == contactArray[j][0]) {
                                                selectedContacts = selectedContacts + " " + contactArray[j][1];
                                            }
                                        }
                                    }

                                    //Zellen mit Inhalt befüllen
                                    accountCell.innerHTML = selectedContacts;
                                    stockCell.innerHTML = nameData;
                                    timeCell.innerHTML = timeData;
                                    percentageCell.innerHTML = percentageData;
                                    buttonCell.appendChild(deleteButton);
                                });
                            });
                        });
                    }

                });
            });
        }
    });
}

//Funktion um Benachrichtigungskonfiguration hinzuzufügen
function addNotify() {
    //Variablen mit den ausgewählten und eingebenen Werten erstellen
    let wkn = document.getElementById("selectOptionNotifyWKN").value
    let percentageString = document.getElementById("sendPercentage").children[0].value;
    let timeString = document.getElementById("sendTime").children[0].value;
    let contacts = $("#selectOptionNotifyContacts").val()

    //Prüfen ob Prozentwert angegeben wurde, sonst Funktion abbrechen
    if (percentageString == "") {
        let e = new Error("Keine Prozentzahl angegeben")
        throw e;
        return;
    }

    //Prüfen ob Zeitraum angegeben wurde, sonst Funktion abbrechen
    if (timeString == "") {
        let e = new Error("Keine Zeit eingegeben")
        throw e;
        return;
    }

    //Prüfen ob mindestens ein Kontakt ausgewählt wurde, sonst Funktion abbrechen
    if (contacts === null) {
        let e = new Error("Kein Kontakt ausgewaehlt")
        throw e;
        return;
    }

    //Prüfen ob Prozentwert und Zeitraum Zahlen sind, sonst Funtion abbrechen
    if (isNaN(percentageString) || isNaN(timeString)) {
        let e = new Error("Zeit und Prozent muessen Zahlen sein")
        throw e;
        return;
    }

    //Aus den Variablen percentageString und timeString float-Variablen erstellen
    let percentage = parseFloat(percentageString);
    let time = parseFloat(timeString);

    //Prüfen ob Prozentwert und Zeitraum über 0 sind, sonst Funktion abbrechen
    if (percentage <= 0 || time <= 0) {
        let e = new Error("Zahlen muessen ueber Null sein")
        throw e;
        return;
    }

    //contactString, enthält die ausgewählten Kontakte in einem String
    let contactString = "";

    //contactString mit den Kontakten befüllen
    for (let i = 0; i < contacts.length; i++) {
        contacts[i] = contacts[i].replace("@", "\\@");
        if (contactString == "") {
            contactString = contactString + contacts[i];
        } else {
            contactString = contactString + "," + contacts[i];
        }

    }

    //Perl-Funktion in FHEM zur Erstellung der Benachrichtigungskonfiguration aufrufen
    ftui.sendFhemCommand('{sendNotificationDefine("' + wkn + '", "' + time + '", "' + percentage + '", "' + contactString + '")}').done(function () {
        //loadNotify() aufrufen
        loadNotify();
    });
}

//Funktion um Benachrichtigungskonfiguration zu löschen, benötigt als Parameter die WKN-Nummer der zugehörigen Aktie
function deleteNotify(wkn) {
    //Perl-Funktion deleteNotify("wkn") in FHEM aufrufen
    let cmd = '{deleteNotify("' + wkn + '")}'
    ftui.sendFhemCommand(cmd).done(function () {
        //Aufrufen von loadNotify()
        loadNotify();
    });

}

//Funktion um Telegrammkontakte in Dropdown-Menü zu laden
function loadContacts() {
    //Dropdown-Menü mit den Kontakten leeren
    $('#selectOptionNotifyContacts').find('option').remove().end();
    //Referenz auf das Dropdown-Menü in die Variable selectContacts speichern
    let selectContacts = document.getElementById("selectOptionNotifyContacts")

    //Perl-Funktion getContactsTele() aus FHEM aufrufen und return-Wert in contactData speicher
    ftui.sendFhemCommand('{getContactsTele()}').done(function (contactData) {
        //aus contactData ein zwei Dimensionales Array erstellen
        //Array matched jeweils Username mit dem Namen
        let users = JSON.parse(contactData);
        let userArray = [];

        for (let j in users) {
            userArray.push([j, users [j]]);
        }

        //für jeden Kontakt ein <option> Element erstellen und hinzufügen
        for (let i = 0; i < userArray.length; i++) {
            let contactOption = document.createElement("option")
            contactOption.setAttribute("value", userArray[i][0]);
            contactOption.innerHTML = userArray[i][1];
            selectContacts.add(contactOption);
        }
    });
}

//Eventhandler, wird ausgelöst beim Laden der Seite
$(window).load(function () {
    loadStocks();
    loadContacts();
    loadNotify();
    setTimeout(() => {
        loadChart()
    }, 2000);
})

//Eventhandler, wird ausgelöst wenn auf das Element mit der ID "addStockButton" gedrückt wird
$("#addStockButton").click(function () {
    if (x == 0) {
        addStock();
        x++;
    } else {
        x = 0;
    }
});

//Eventhandler, wird ausgelöst wenn sich der Wert des Elements mit der ID "selectOptionPerformance" ändert
$("#selectOptionPerformance").change(function () {
    loadChart();
});

//Eventhandler, wird ausgelöst wenn sich der Wert des Elements mit der ID "selectOptionTimes" ändert
$("#selectOptionTimes").change(function () {
    loadChart();
});

//Eventhandler, wird ausgelöst wenn sich der Wert des Elements mit der ID "selectOptionChange" ändert
$("#selectOptionChange").change(function () {
    loadStocks();
});

//Eventhandler, wird ausgelöst wenn auf das Element mit der ID "addNotifyButton" gedrückt wird
$("#addNotifyButton").click(function () {
    if (x == 0) {
        addNotify();
        x++;
    } else {
        x = 0;
    }
});

//Eventhandler, wird ausgelöst wenn die Fenstergröße geändert wird
$(window).resize(function () {
    location.reload();
})


