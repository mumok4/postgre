CREATE TYPE public.measurement_data AS (
    temperature numeric(8,2),
    pressure numeric(8,2),
    wind_direction numeric(8,2),
    wind_speed numeric(8,2),
    height numeric(8,2)
);

CREATE TABLE IF NOT EXISTS public.measure_settings (
    id integer PRIMARY KEY NOT NULL,
    parameter_name character varying(50),
    min_value numeric(8,2),
    max_value numeric(8,2),
    unit_name character varying(50),
    description text
);

CREATE SEQUENCE IF NOT EXISTS measure_settings_seq START 6;
ALTER TABLE measure_settings ALTER COLUMN id SET DEFAULT nextval('public.measure_settings_seq');

CREATE TABLE IF NOT EXISTS public.devices (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name character varying(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name character varying(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.measurements (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    height numeric(8,2) NOT NULL,
    temperature numeric(8,2) NOT NULL,
    pressure numeric(8,2) NOT NULL,
    wind_speed numeric(8,2) NOT NULL,
    wind_direction numeric(8,2) NOT NULL,
    measurement_date timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    post_id uuid NOT NULL,
    fullname character varying(100) NOT NULL,
    age numeric(8,2) NOT NULL,
    FOREIGN KEY (post_id) REFERENCES public.posts(id)
);

CREATE TABLE IF NOT EXISTS public.history (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL,
    measurement_id uuid NOT NULL,
    device_id uuid NOT NULL,
    longitude numeric(4,2) NOT NULL,
    latitude numeric(4,2) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES public.users(id),
    FOREIGN KEY (measurement_id) REFERENCES public.measurements(id),
    FOREIGN KEY (device_id) REFERENCES public.devices(id)
);

INSERT INTO public.measure_settings
(id, parameter_name, min_value, max_value, unit_name, description)
VALUES
(1, 'temperature', -58.00, 58.00, 'цельсии', 'Температура воздуха'),
(2, 'pressure', 500.00, 900.00, 'ммРс', 'Атмосферное давление'),
(3, 'wind_direction', 0.00, 59.00, 'градусы', 'Направление ветра'),
(4, 'wind_speed', 0.00, 100.00, 'м/с', 'Скорость ветра'),
(5, 'height', 0.00, 1000.00, 'м', 'Высота измерения');

CREATE OR REPLACE FUNCTION public.validate_measurement(
    height numeric(8,2),
    temperature numeric(8,2),
    pressure numeric(8,2),
    wind_speed numeric(8,2),
    wind_direction numeric(8,2)
)
RETURNS public.measurement_data
LANGUAGE plpgsql
AS $$
DECLARE
    result public.measurement_data;
BEGIN
    IF temperature < (SELECT min_value FROM public.measure_settings WHERE parameter_name = 'temperature')
        OR temperature > (SELECT max_value FROM public.measure_settings WHERE parameter_name = 'temperature') THEN
        RAISE EXCEPTION 'Значение температуры % вне допустимого диапазона', temperature;
    END IF;

    IF pressure < (SELECT min_value FROM public.measure_settings WHERE parameter_name = 'pressure')
        OR pressure > (SELECT max_value FROM public.measure_settings WHERE parameter_name = 'pressure') THEN
        RAISE EXCEPTION 'Значение давления % вне допустимого диапазона', pressure;
    END IF;

    IF wind_direction < (SELECT min_value FROM public.measure_settings WHERE parameter_name = 'wind_direction')
        OR wind_direction > (SELECT max_value FROM public.measure_settings WHERE parameter_name = 'wind_direction') THEN
        RAISE EXCEPTION 'Значение направления ветра % вне допустимого диапазона', wind_direction;
    END IF;

    IF wind_speed < (SELECT min_value FROM public.measure_settings WHERE parameter_name = 'wind_speed')
        OR wind_speed > (SELECT max_value FROM public.measure_settings WHERE parameter_name = 'wind_speed') THEN
        RAISE EXCEPTION 'Значение скорости ветра % вне допустимого диапазона', wind_speed;
    END IF;

    IF height < (SELECT min_value FROM public.measure_settings WHERE parameter_name = 'height')
        OR height > (SELECT max_value FROM public.measure_settings WHERE parameter_name = 'height') THEN
        RAISE EXCEPTION 'Значение высоты % вне допустимого диапазона', height;
    END IF;

    result.height := height;
    result.temperature := temperature;
    result.pressure := pressure;
    result.wind_speed := wind_speed;
    result.wind_direction := wind_direction;

    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.insert_measurement(
    p_height numeric(8,2),
    p_temperature numeric(8,2),
    p_pressure numeric(8,2),
    p_wind_speed numeric(8,2),
    p_wind_direction numeric(8,2),
    p_user_id uuid,
    p_device_id uuid,
    p_longitude numeric(4,2),
    p_latitude numeric(4,2)
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    validated_data public.measurement_data;
    new_measurement_id uuid;
BEGIN
    validated_data := public.validate_measurement(
        p_height,
        p_temperature,
        p_pressure,
        p_wind_speed,
        p_wind_direction
    );

    INSERT INTO public.measurements (
        height,
        temperature,
        pressure,
        wind_speed,
        wind_direction
    ) VALUES (
        validated_data.height,
        validated_data.temperature,
        validated_data.pressure,
        validated_data.wind_speed,
        validated_data.wind_direction
    ) RETURNING id INTO new_measurement_id;

    INSERT INTO public.history (
        user_id,
        measurement_id,
        device_id,
        longitude,
        latitude
    ) VALUES (
        p_user_id,
        new_measurement_id,
        p_device_id,
        p_longitude,
        p_latitude
    );

    RETURN new_measurement_id;
END;
$$;
