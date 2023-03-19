# Generated by Django 3.2.18 on 2023-03-18 21:29

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='AirportEmployees',
            fields=[
                ('icao_code', models.CharField(max_length=4, primary_key=True, serialize=False, verbose_name='Unique ICAO airport code')),
                ('name', models.CharField(db_index=True, max_length=100, verbose_name='Airport name')),
                ('num_employees', models.IntegerField(verbose_name='Number of Employees')),
            ],
            options={
                'db_table': 'airport_and_based_crew',
                'managed': False,
            },
        ),
        migrations.CreateModel(
            name='AirportStats',
            fields=[
                ('icao_code', models.CharField(max_length=4, primary_key=True, serialize=False, verbose_name='Unique ICAO airport code')),
                ('avg_delay', models.FloatField(verbose_name='Average Delay')),
                ('num_flights', models.IntegerField(verbose_name='Number of Flights')),
                ('num_passengers', models.IntegerField(verbose_name='Number of Passengers')),
            ],
            options={
                'db_table': 'airport_stats',
                'managed': False,
            },
        ),
        migrations.CreateModel(
            name='Airport',
            fields=[
                ('icao_code', models.CharField(max_length=4, primary_key=True, serialize=False, verbose_name='Unique ICAO airport code')),
                ('name', models.CharField(db_index=True, max_length=100, verbose_name='Airport name')),
                ('raa', models.IntegerField(null=True)),
            ],
        ),
    ]