//JavaScript-Datei für index.html

//Funktion um Aktientabelle zu laden
function loadStocks(){
    //Referenz auf die Aktientabelle in die Variable stockTable speichern
    let stockTable = document.getElementById("stockTable");

    //Akien aus FHEM auslesen und in stockData speichern
    ftui.sendFhemCommand('{getStocks()}').done(function (stockData){
        //Array aus stockData erstellen
        let stocks = JSON.parse(stockData);

        for(let i = 0; i < stocks.length; i++){

            //Readings auslesen
            ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Name","undefined")}').done(function (nameData) {
                ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "Price","undefined")}').done(function (priceData) {
                    ftui.sendFhemCommand('{ReadingsVal("' + stocks[i].toUpperCase() + '", "RelativeChange","undefined")}').done(function (changeData) {

                        //Neue Tabellenreihe erstellen
                        let stockRow = stockTable.insertRow(-1);

                        //Zellen in der Tabellenreihe erstellen
                        let stockCell = stockRow.insertCell(0);
                        let wknCell = stockRow.insertCell(1);
                        let valueCell = stockRow.insertCell(2);
                        let changeCell = stockRow.insertCell(3);

                        //Zellen mit Inhalt befüllen
                        stockCell.innerHTML = nameData;
                        wknCell.innerHTML = stocks[i];
                        valueCell.innerHTML = priceData;
                        changeCell.innerHTML = changeData;
                    });
                });
            });
        }
    });
}

//Eventhändler löst aus wenn Seite geladen wird
$(window).load(function() {
    loadStocks();
})