import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moon_phase/download/download.dart';
import 'package:moon_phase/moon_phase.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moon Phase Generator',
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Moon Phase Calendar Generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTimeRange? dateRange;

  List<Tuple3<DateTime, String, int>> moonDates = [];

  void generateMoonPhase() {
    moonDates.clear();
    var day = dateRange!.start.toUtc();
    while (day.compareTo(dateRange!.end) < 1) {
      final age = Moon.ageOfMoon(day);
      final phase = Moon.getMoonPhase(age);
      moonDates.add(Tuple3(day, phase!.name.toCapitalCase(), age.toInt()));
      day = day.add(const Duration(hours: 24));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: CustomScrollView(
        slivers: [
          Builder(
            builder: (
              context,
            ) {
              return dateRange == null
                  ? const SliverFillRemaining(
                      child: Center(child: Text('No date range selected')))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = moonDates[index];
                          return ListTile(
                            title:
                                Text('Moon day ${item.item3} - ${item.item2}'),
                            subtitle: Text(
                                '${item.item1} - ${DateFormat.EEEE().format(item.item1)} - ${item.item1.timeZoneName}\n'
                                '${item.item1.toLocal()} - ${DateFormat.EEEE().format(item.item1.toLocal())} - ${item.item1.toLocal().timeZoneName}'),
                          );
                        },
                        childCount: moonDates.length,
                      ),
                    );
            },
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                initialDateRange: dateRange,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  dateRange = picked;
                  generateMoonPhase();
                });
              }
            },
            label: Text(dateRange == null
                ? 'Choose date range'
                : '${dateRange!.start} - ${dateRange!.end}'),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () async {
              if (dateRange == null) {
                return;
              }

              // create the .ics file and write the events to it
              String fileName =
                  '${DateFormat('yyyy_MM_dd').format(dateRange!.start)}_moon_phases.ics';
              StringBuffer sink = StringBuffer();

              sink.write('BEGIN:VCALENDAR\n');
              sink.write('VERSION:2.0\n');
              sink.write('PRODID:-//My Calendar//NONSGML v1.0//EN\n');

              for (int i = 0; i < moonDates.length; i++) {
                final item = moonDates[i];
                String phaseName = item.item2;
                sink.write('BEGIN:VEVENT\n');

                /// in UTC by default
                sink.write(
                    'DTSTART;VALUE=DATE:${DateFormat('yyyyMMddTHHmmss').format(item.item1)}Z\n');
                sink.write('SUMMARY:Moon phase: $phaseName\n');
                sink.write(
                    'DESCRIPTION:Moon day: ${item.item3}. Generate more dates at starcabbage.github.io/moon_calendar_generator\n');
                sink.write(
                    'URL:https://starcabbage.github.io/moon_calendar_generator/\n');
                sink.write('END:VEVENT\n');
              }

              sink.write('END:VCALENDAR\n');

              final Uint8List bytes =
                  Uint8List.fromList(utf8.encode(sink.toString()));
              download(bytes, downloadName: fileName);
            },
            tooltip: 'Generate',
            child: const Icon(Icons.file_download),
          ),
        ],
      ),
    );
  }
}
