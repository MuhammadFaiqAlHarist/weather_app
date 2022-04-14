import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main(List<String> args) => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int? temperature;
  String location = 'Jakarta';
  String weather = 'clear';

  int woeid = 1047378;
  String abbreviation = 'c';

  String errorMessage = '';

  //buat var untuk list temperaturenya
  var minTemperatureForecast = List.filled(7, 0);
  var maxTemperatureForecast = List.filled(7, 0);
  var abbrevationForecast = List.filled(7, '');

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';

  String locationApiUrl = 'https://www.metaweather.com/api/location/search/';

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  Future<void> fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiUrl + input));
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
      });
    } catch (error) {
      errorMessage =
          "Maaf kita tidak ada data untuk kata itu, coba bre cari yang lain";
    }
  }

  Future<void> fetchLocation() async {
    var locationResult =
        await http.get(Uri.parse(locationApiUrl + woeid.toString()));
    var result = json.decode((locationResult.body));
    var consolidated_weather = result['consolidated_weather'];
    var data = consolidated_weather[0];

    setState(() {
      temperature = data['the-temp'].round();
      weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
      abbreviation = data['weather_state_name'];
    });
  }

  Future<void> fetchLocationDay() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(Uri.parse(locationApiUrl +
          woeid.toString() +
          '/' +
          DateFormat('y/M/d')
              .format(today.add(Duration(days: i + 1)))
              .toString()));
      var result = jsonDecode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data['min_temp'].round();
        maxTemperatureForecast[i] = data['max_temp'].round();
        abbrevationForecast[i] = data['weather_state_abbr'];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchLocation();
    await fetchSearch(input);
    await fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/$weather.png'), fit: BoxFit.cover)),
        child: temperature == null
            ? const Center(child: CircularProgressIndicator())
            : Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Image.network(
                            'https://www.metaweather.com/static/img/weather/c.svg' +
                                abbreviation +
                                '.png',
                            width: 100,
                          ),
                        ),
                        Center(
                          child: Text(
                            temperature.toString() + '°C',
                            style: TextStyle(color: Colors.white, fontSize: 60),
                          ),
                        ),
                        Center(
                          child: Text(
                            location,
                            style: TextStyle(color: Colors.white, fontSize: 40),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++) 
                            forecastElement(
                              i+1,
                              abbrevationForecast[i],
                              maxTemperatureForecast[i],
                              minTemperatureForecast
                            )
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 300,
                          child: TextField(
                            onChanged: (String input) {
                              onTextFieldSubmitted(input);
                            },
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            decoration: InputDecoration(
                                hintText: 'search another location...',
                                hintStyle: TextStyle(
                                    color: Colors.white, fontSize: 10),
                                prefixIcon: Icon(Icons.search)),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: Platform.isAndroid ? 15 : 20),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}

Widget forecastElement(
    daysFromNow, abbreviation, maxTemperature, minTemperature) {
  var now = DateTime.now();
  var oneDayFromNow = now.add(Duration(days: daysFromNow));
  return Padding(
    padding: EdgeInsets.only(
      left: 16,
    ),
    child: Container(
      decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat.E().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              DateFormat.E().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16,
              ),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/c.svg' +
                    abbreviation +
                    '.png',
                width: 100,
              ),
            ),
            Text(
              'High' + maxTemperature.toString() + '°C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              'Low' + minTemperature.toString() + '°C',
              style: TextStyle(color: Colors.white, fontSize: 20),
            )
          ],
        ),
      ),
    ),
  );
}
