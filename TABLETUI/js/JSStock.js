let x = 0;

//Funktion zum Laden der Aktien
function loadStocks() {
    let selectPerformanceWKN = document.getElementById("selectOptionPerformance");
    let selectNotifyWKN = document.getElementById("selectOptionNotifyWKN");
    let stockTable = document.getElementById("stockTable");
    let selectChange = document.getElementById("selectOptionChange").value;
    let change;
    if (selectChange == "1") {
        change = "RelativeChange"
    } else {
        change = "AbsolutChange"
    }
    ftui.sendFhemCommand('{getStocks()}').done(function (stockData) {
        $("#aktientable").empty();
        $('#selectOptionPerformance').find('option').remove().end();
        $('#selectOptionNotifyWKN').find('option').remove().end();

        let stocks = JSON.parse(stockData);

        for (let i = 0; i < stocks.length; i++) {
            ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Name","undefined")}').done(function (nameData) {
                ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Price","undefined")}').done(function (priceData) {
                    ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "' + change + '","undefined")}').done(function (changeData) {
                        let name = nameData;
                        let price = priceData;
                        let change = changeData;

                        let stockRow = stockTable.insertRow(-1);

                        let stockCell = stockRow.insertCell(0);
                        let wknCell = stockRow.insertCell(1);
                        let valueCell = stockRow.insertCell(2);
                        let changeCell = stockRow.insertCell(3);
                        let buttonCell = stockRow.insertCell(4);


                        let deleteButton = document.createElement("button");
                        deleteButton.setAttribute("onclick", "deleteStock(\"" + stocks[i] + "\")");
                        deleteButton.innerHTML = "Aktie loeschen";
                        deleteButton.setAttribute("class", "buttonCell");


                        stockCell.innerHTML = name;
                        wknCell.innerHTML = stocks[i];
                        valueCell.innerHTML = price;
                        changeCell.innerHTML = change;
                        buttonCell.appendChild(deleteButton);


                        let optionPerformanceWKN = document.createElement("option");
                        optionPerformanceWKN.setAttribute("value", i);
                        optionPerformanceWKN.innerHTML = name;

                        let optionNotifyWKN = optionPerformanceWKN.cloneNode(true);

                        selectPerformanceWKN.add(optionPerformanceWKN);
                        selectNotifyWKN.add(optionNotifyWKN);

                    });
                });
            });
        }
    });
}

function addStock() {
    let wkn = document.getElementById("sendWKN").children[0].value;
    if (wkn != "") {
        let cmd = '{addStock("' + wkn + '")}'
        ftui.sendFhemCommand(cmd).done(function () {
            loadStocks();
        });
    }
    document.getElementById("sendWKN").children[0].value = "";
}

function deleteStock(wkn) {
    let cmd = '{deleteStock("' + wkn + '")}';
    ftui.sendFhemCommand(cmd).done(function () {
        loadStocks();
        loadNotify();
    });

}

function loadChart() {
    let oldCanvas = document.getElementById("stockChart");
    let canvas = oldCanvas.cloneNode(false);
    oldCanvas.remove();
    document.getElementById("canvasDiv").appendChild(canvas);
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

    ftui.sendFhemCommand('{getStocks()}').done(function (stockData) {
        let selectedStock = document.getElementById("selectOptionPerformance").value
        let stocks = JSON.parse(stockData);
        let wkn = stocks[selectedStock];
        ftui.sendFhemCommand('{getLogs("' + wkn + '", "' + dateString + '")}').done(function (logs) {

            let logFileArray = logs.split("\n");
            let logRowArray = new Array();

            for (let i = 0; i < logFileArray.length; i++) {
                logFileArray[i] = logFileArray[i].replaceAll(".", "");
                logFileArray[i] = logFileArray[i].replaceAll(",", ".");
                logRowArray[i] = logFileArray[i].split(" ");
            }

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


            let chart = new Chart(canvas, {
                type: 'line',
                data: {
                    labels: dates,
                    datasets: [{
                        data: values,
                        label: "Aktienkurs",
                        borderColor: "#3e95cd",
                        fill: false
                    },
                    ]
                },
                options: {
                    elements: {
                        line: {
                            tension: 0 // disables bezier curves
                        }
                    },
                    title: {
                        display: true,
                        text: 'Kursverlauf'
                    },
                    scales: {
                        xAxes: [{
                            display: false //this will remove all the x-axis grid lines
                        }]
                    }
                }
            });
        });
    });
}


function loadNotify() {
    let notifyTable = document.getElementById("notifyTable")
    $("#notifyTable").empty();

    ftui.sendFhemCommand('{getStocks}').done(function (stockData) {
        let stocks = JSON.parse(stockData);

        for (let i = 0; i < stocks.length; i++) {
            ftui.sendFhemCommand('{AttrVal("' + stocks[i].toUpperCase() + '", "ChangePercent","undefined")}').done(function (percentageData) {
                let percent = percentageData;

                ftui.sendFhemCommand('{AttrVal("' + stocks[i].toUpperCase() + '", "ChangeTime","undefined")}').done(function (timeData) {
                    let changeTime = timeData;
                    if (!isNaN(changeTime)) {

                        ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Name","undefined")}').done(function (nameData) {
                            let name = nameData;

                            ftui.sendFhemCommand('{AttrVal("' + stocks[i].toUpperCase() + '", "Contacts","undefined")}').done(function (usernameData) {

                                let usernames = usernameData.split(",");

                                ftui.sendFhemCommand('{getContactsTele()}').done(function (contactData) {

                                    let userContacts = JSON.parse(contactData);
                                    let contactArray = [];

                                    for (let j in userContacts) {
                                        contactArray.push([j, userContacts [j]]);
                                    }


                                    let tableRow = notifyTable.insertRow(-1);


                                    let accountCell = tableRow.insertCell(0);
                                    let stockCell = tableRow.insertCell(1);
                                    let timeCell = tableRow.insertCell(2);
                                    let percentageCell = tableRow.insertCell(3);
                                    let buttonCell = tableRow.insertCell(4);

                                    let deleteButton = document.createElement("button");
                                    deleteButton.setAttribute("onclick", "deleteNotify(\"" + stocks[i] + "\")");
                                    deleteButton.setAttribute("class", "buttonCell");
                                    deleteButton.innerHTML = "Benachrichtigung loeschen";

                                    let selectedContacts = "";

                                    for (let k = 0; k < usernames.length; k++) {
                                        usernames[k] = usernames[k].replaceAll("\n", "")
                                        for (let j = 0; j < contactArray.length; j++) {
                                            if (usernames[k] == contactArray[j][0]) {
                                                selectedContacts = selectedContacts + " " + contactArray[j][1];
                                            }
                                        }
                                    }

                                    accountCell.innerHTML = selectedContacts;
                                    stockCell.innerHTML = name;
                                    timeCell.innerHTML = changeTime;
                                    percentageCell.innerHTML = percent;
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


function addNotify() {
    let value = document.getElementById("selectOptionNotifyWKN").value
    let percentageString = document.getElementById("sendPercentage").children[0].value;
    let timeString = document.getElementById("sendTime").children[0].value;
    let contacts = $("#selectOptionNotifyContacts").val()


    if (percentageString == "") {
        let e = new Error("Keine Prozentzahl angegeben")
        throw e;
        return;
    }

    if (timeString == "") {
        let e = new Error("Keine Zeit eingegeben")
        throw e;
        return;
    }

    if (contacts === null) {
        let e = new Error("Kein Kontakt ausgewaehlt")
        throw e;
        return;
    }


    if (isNaN(percentageString) || isNaN(timeString)) {
        let e = new Error("Zeit und Prozent muessen Zahlen sein")
        throw e;
        return;
    }

    let percentage = parseFloat(percentageString);
    let time = parseFloat(timeString);

    if (percentage <= 0 || time <= 0) {
        let e = new Error("Zahlen muessen ueber Null sein")
        throw e;
        return;
    }

    let contactString = "";

    for (let i = 0; i < contacts.length; i++) {
        contacts[i] = contacts[i].replace("@", "\\@");
        if (contactString == "") {
            contactString = contactString + contacts[i];
        } else {
            contactString = contactString + "," + contacts[i];
        }

    }

    ftui.sendFhemCommand('{getStocks()}').done(function (stockData) {
        let stocks = JSON.parse(stockData);
        let wkn = stocks[value];
        ftui.sendFhemCommand('{sendNotificationDefine("' + wkn + '", "' + time + '", "' + percentage + '", "' + contactString + '")}').done(function () {

            loadNotify();
        });
    });
}

function deleteNotify(wkn) {
    let cmd = '{deleteNotify("' + wkn + '")}'
    ftui.sendFhemCommand(cmd).done(function () {
        loadNotify();
    });

}

function loadContacts() {
    $('#selectOptionNotifyContacts').find('option').remove().end();
    let selectContacts = document.getElementById("selectOptionNotifyContacts")

    ftui.sendFhemCommand('{getContactsTele()}').done(function (contactData) {
        let users = JSON.parse(contactData);
        let userArray = [];

        for (let j in users) {
            userArray.push([j, users [j]]);
        }

        for (let i = 0; i < userArray.length; i++) {
            let contactOption = document.createElement("option")
            contactOption.setAttribute("value", userArray[i][0]);
            contactOption.innerHTML = userArray[i][1];
            selectContacts.add(contactOption);
        }
    });
}


$(window).load(function () {
    loadStocks();
    loadContacts();
    loadNotify();
    setTimeout(() => {
        loadChart()
    }, 2000);
})


$("#addStockButton").click(function () {
    if (x == 0) {
        addStock();
        x++;
    } else {
        x = 0;
    }
});

$("#selectOptionPerformance").change(function () {
    loadChart();
});

$("#selectOptionTimes").change(function () {
    loadChart();
});

$("#selectOptionChange").change(function () {
    loadStocks();
});

$("#addNotifyButton").click(function () {
    if (x == 0) {
        addNotify();
        x++;
    } else {
        x = 0;
    }
});

$(window).resize(function () {
    location.reload();
})


