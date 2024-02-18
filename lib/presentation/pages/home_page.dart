import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import "package:intl/intl.dart";
import 'package:weather_service/cubit/cubit/home_cubit.dart';
import 'package:weather_service/data/models/weather.dart';
import 'package:weather_service/presentation/utils/assets.dart';
import 'package:weather_service/presentation/utils/colors.dart';
import 'package:weather_service/presentation/utils/extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Weather _weather;

  @override
  void initState() {
    super.initState();
    // get weather from hive
    final weather = Hive.box('myBox').get('weather');
    if (weather != null && weather is Weather) {
      _weather = weather;
    } else {
      _weather = Weather.empty();
    }
    context.read<HomeCubit>().getWeatherByLocation();
  }

  // get big weather image
  String _getWeatherImage({
    required int weatherId,
    required bool isDay,
    required bool isBig,
  }) {
    if (weatherId >= 200 && weatherId < 300) {
      if (isBig) {
        return PngAsset.thunderstormBig;
      } else {
        return PngAsset.thunderstormSmall;
      }
    } else if (weatherId >= 300 && weatherId < 400) {
      if (isBig) {
        return PngAsset.drizzleBig;
      } else {
        return PngAsset.drizzleSmall;
      }
    } else if (weatherId >= 500 && weatherId < 600) {
      if (isBig) {
        return PngAsset.rainBig;
      } else {
        return PngAsset.drizzleSmall;
      }
    } else if (weatherId >= 600 && weatherId < 700) {
      if (isBig) {
        return PngAsset.snowBig;
      } else {
        return PngAsset.snowSmall;
      }
      // } else if (weatherId >= 700 && weatherId < 800) {
      //   if (isBig) {
      //     return PngAsset.atmosphereBig;
      //   } else {
      //     return PngAsset.atmosphereSmall;
      //   }
    } else if (weatherId == 800) {
      if (isBig) {
        return PngAsset.clearSkyBig;
      } else {
        return PngAsset.clearSkySmall;
      }
    } else if (weatherId > 800 && weatherId < 900) {
      if (isBig) {
        return PngAsset.fewCloudsBig;
      } else {
        return isDay
            ? PngAsset.fewCloudsDaySmall
            : PngAsset.fewCloudsNightSmall;
      }
    } else {
      return PngAsset.clearSkySmall;
    }
  }

  // get today's min and max temperature
  String _getMinMaxTemp(Weather weather) {
    // * openweathermap returns 5 days forecast with 3 hours interval
    // map through today's temperatures check dt_txt for today's date
    final todayTemps = weather.list
        .map((e) => e)
        .where((e) =>
            e.dtTxt.contains(DateFormat('yyyy-MM-dd').format(DateTime.now())))
        .toList();

    // get max and min temperature
    final maxTemp = todayTemps
        .map((e) => e.main.tempMax)
        .reduce((value, element) => value > element ? value : element);
    final minTemp = todayTemps
        .map((e) => e.main.tempMin)
        .reduce((value, element) => value < element ? value : element);

    return 'Мах: ${maxTemp.toStringAsFixed(0)}º Min: ${minTemp.toStringAsFixed(0)}º';
  }

  // return date in russian
  String _getIndiaDate(String date) {
    final months = {
      '01': 'January',
      '02': 'February',
      '03': 'Маrch',
      '04': 'April',
      '05': 'May',
      '06': 'June',
      '07': 'July',
      '08': 'August',
      '09': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
    };

    final dateParts = date.split('-');
    final dateOnly = dateParts[2].split(' ')[0];
    return '$dateOnly ${months[dateParts[1]]}';
  }

  // get humidity description
  String _getHumidityDescription(int humidity) {
    if (humidity < 30) {
      return 'Dry';
    } else if (humidity < 60) {
      return 'Fine';
    } else {
      return 'Humid';
    }
  }

  // get wind description (direction)
  String _getWindDescription(int windDeg) {
    String windText = "Wind";
    if (windDeg >= 0 && windDeg < 45) {
      windText += " Northern";
    } else if (windDeg >= 45 && windDeg < 90) {
      windText += " Northeastern";
    } else if (windDeg >= 90 && windDeg < 135) {
      windText += " Oriental";
    } else if (windDeg >= 135 && windDeg < 180) {
      windText += " Southeastern";
    } else if (windDeg >= 180 && windDeg < 225) {
      windText += " Southern";
    } else if (windDeg >= 225 && windDeg < 270) {
      windText += " Southwestern";
    } else if (windDeg >= 270 && windDeg < 315) {
      windText += " West";
    } else if (windDeg >= 315 && windDeg < 360) {
      windText += " North-West";
    }

    return windText;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: errorColor,
            ),
          );
        }
        if (state is HomeLoaded) {
          _weather = state.weather;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data updated'),
            ),
          );
        }
        if (state is HomeLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loading...'),
            ),
          );
        }
      },
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              constraints: const BoxConstraints.expand(),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 0,
                24,
                24,
              ),
              decoration: BoxDecoration(
                gradient: primaryLightGradient,
              ),
              child: _weather.list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: whiteColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Check your internet connection',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: whiteColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              SvgPicture.asset(SvgAsset.pin),
                              const SizedBox(width: 8),
                              Text(
                                '${_weather.city.name}, ${_weather.city.country}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: whiteColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Container(
                            height: 200,
                            width: 200,
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 100,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child:
                                // Image.network(
                                //   'https://openweathermap.org/img/w/${_weather.list.first.weather.first.icon}.png',
                                //   width: 200,
                                //   height: 200,
                                //   scale: 0.3,
                                // ),
                                Image.asset(
                              _getWeatherImage(
                                weatherId: _weather.list.first.weather.first.id,
                                isBig: true,
                                isDay: _weather.list.first.sys.pod == 'd',
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),
                          Text(
                            '${_weather.list.first.main.temp.toStringAsFixed(0)}º',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: whiteColor,
                              fontSize: 64,
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // Text(
                          //   _weather.list.first.weather.first.description
                          //       .capitalize(),
                          //   style: const TextStyle(
                          //     color: whiteColor,
                          //     fontSize: 17,
                          //     fontWeight: FontWeight.w400,
                          //   ),
                          // ),
                          const SizedBox(height: 8),
                          Text(
                            _getMinMaxTemp(_weather),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: whiteColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // today's weather hourly
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: whiteColor.withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            height: 230,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Today',
                                        style: TextStyle(
                                          color: whiteColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _getIndiaDate(
                                            _weather.list.first.dtTxt),
                                        style: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                  color: whiteColor,
                                  thickness: 1,
                                  height: 1,
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _weather.list.length,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        padding: const EdgeInsets.all(
                                          16,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          // if right now give white color with opacity 0.2
                                          color: index == 0
                                              ? whiteColor.withOpacity(0.2)
                                              : Colors.transparent,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              DateFormat('HH:MM').format(
                                                DateTime.parse(
                                                  _weather.list[index].dtTxt,
                                                ),
                                              ),
                                              style: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Image.network(
                                            //   'https://openweathermap.org/img/w/${_weather.list[index].weather.first.icon}.png',
                                            //   width: 32,
                                            //   height: 32,
                                            // ),
                                            Image.asset(
                                              _getWeatherImage(
                                                weatherId: _weather.list[index]
                                                    .weather.first.id,
                                                isDay: _weather
                                                        .list[index].sys.pod ==
                                                    'd',
                                                isBig: false,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${_weather.list[index].main.temp.toStringAsFixed(0)}º',
                                              style: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // today's weather wind, humidity
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: whiteColor.withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(SvgAsset.drop),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_weather.list.first.main.humidity}%',
                                      style: const TextStyle(
                                        color: whiteColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _getHumidityDescription(
                                          _weather.list.first.main.humidity),
                                      style: const TextStyle(
                                        color: whiteColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    SvgPicture.asset(SvgAsset.wind),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_weather.list.first.wind.speed} м/с',
                                      style: const TextStyle(
                                        color: whiteColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _getWindDescription(
                                          _weather.list.first.wind.deg),
                                      style: const TextStyle(
                                        color: whiteColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
