do $$
begin

 drop view if exists vw_report_fails_statistics;
 drop view if exists vw_report_fails_height_statistics;

raise notice 'Запускаем создание новой структуры базы данных meteo'; 
begin

	alter table if exists public.measurment_input_params
	drop constraint if exists measurment_type_id_fk;

	alter table if exists public.employees
	drop constraint if exists military_rank_id_fk;

	alter table if exists public.measurment_baths
	drop constraint if exists measurment_input_param_id_fk;

	alter table if exists public.measurment_baths
	drop constraint if exists emploee_id_fk;

	alter table if exists public.calc_correction_types
	drop constraint if exists calc_correction_types_measurment_type_id_fk;

	alter table if exists public.calc_corrections
	drop constraint if exists  calc_corrections_calc_height_id_fk;

	alter table if exists public.calc_corrections
	drop constraint if exists  calc_corrections_calc_correction_type_id_fk;

	alter table if  exists public.calc_correction_types
	drop constraint if exists  calc_correction_types_parent_id_fk;

	drop table if exists public.measurment_input_params;
	drop table if exists public.measurment_baths;
	drop table if exists public.employees;
	drop table if exists public.measurment_types;
	drop table if exists public.military_ranks;
	drop table if exists public.measurment_settings;

	drop table if exists public.calc_corrections_temperature;
	drop table if exists public.calc_correction_types;
	drop table if exists public.calc_corrections;
	drop table if exists public.calc_corrections_height;
	DROP TABLE IF EXISTS temp_input_params;

	drop sequence if exists public.measurment_input_params_seq cascade;
	drop sequence if exists public.measurment_baths_seq cascade;
	drop sequence if exists public.employees_seq cascade;
	drop sequence if exists public.military_ranks_seq cascade;
	drop sequence if exists public.measurment_types_seq cascade;

	drop sequence if exists public.calc_corrections_temperature_seq cascade;
	drop sequence if exists public.calc_correction_types_seq cascade;
	drop sequence if exists public.calc_corrections_seq cascade;
	drop sequence if exists public.calc_corrections_height_seq cascade;
	DROP SEQUENCE IF EXISTS temp_input_params_seq cascade;

end;

raise notice 'Удаление старых данных выполнено успешно';

create table military_ranks
(
	id integer primary key not null,
	description character varying(255)
);

insert into military_ranks(id, description)
values(1,'Рядовой'),(2,'Лейтенант');

create sequence military_ranks_seq start 3;

alter table military_ranks alter column id set default nextval('public.military_ranks_seq');

create table employees
(
    id integer primary key not null,
	name text,
	birthday timestamp ,
	military_rank_id integer not null
);

insert into employees(id, name, birthday,military_rank_id )  
values(1, 'Воловиков Александр Сергеевич','1978-06-24', 2);

create sequence employees_seq start 2;

alter table employees alter column id set default nextval('public.employees_seq');

create table measurment_types
(
   id integer primary key not null,
   short_name  character varying(50),
   description text 
);

insert into measurment_types(id, short_name, description)
values(1, 'ДМК', 'Десантный метео комплекс'),
(2,'ВР','Ветровое ружье');

create sequence measurment_types_seq start 3;

alter table measurment_types alter column id set default nextval('public.measurment_types_seq');

create table measurment_input_params 
(
    id integer primary key not null,
	measurment_type_id integer not null,
	height numeric(8,2) default 0,
	temperature numeric(8,2) default 0,
	pressure numeric(8,2) default 0,
	wind_direction numeric(8,2) default 0,
	wind_speed numeric(8,2) default 0,
	bullet_demolition_range numeric(8,2) default 0
);

insert into measurment_input_params(id, measurment_type_id, height, temperature, pressure, wind_direction,wind_speed )
values(1, 1, 100,12,34,0.2,45);

create sequence measurment_input_params_seq start 2;

alter table measurment_input_params alter column id set default nextval('public.measurment_input_params_seq');

create table measurment_baths
(
		id integer primary key not null,
		emploee_id integer not null,
		measurment_input_param_id integer not null,
		started timestamp default now()
);

insert into measurment_baths(id, emploee_id, measurment_input_param_id)
values(1, 1, 1);

create sequence measurment_baths_seq start 2;

alter table measurment_baths alter column id set default nextval('public.measurment_baths_seq');

create table measurment_settings
(
	key character varying(100) primary key not null,
	value  character varying(255) ,
	description text
);

insert into measurment_settings(key, value, description)
values('min_temperature', '-10', 'Минимальное значение температуры'), 
('max_temperature', '50', 'Максимальное значение температуры'),
('min_pressure','500','Минимальное значение давления'),
('max_pressure','900','Максимальное значение давления'),
('min_wind_direction','0','Минимальное значение направления ветра'),
('max_wind_direction','59','Максимальное значение направления ветра'),
('calc_table_temperature','15.9','Табличное значение температуры'),
('calc_table_pressure','750','Табличное значение наземного давления'),
('min_height','0','Минимальная высота'),
('max_height','400','Максимальная высота');

raise notice 'Создание общих справочников и наполнение выполнено успешно'; 

create table calc_corrections_temperature
(
   temperature numeric(8,2) not null primary key,
   correction numeric(8,2) not null
);

insert into public.calc_corrections_temperature(temperature, correction)
Values(0, 0.5),(5, 0.5),(10, 1), (20,1), (25, 2), (30, 3.5), (40, 4.5);

drop type  if exists interpolation_type cascade;
create type interpolation_type as
(
	x0 numeric(8,2),
	x1 numeric(8,2),
	y0 numeric(8,2),
	y1 numeric(8,2)
);

drop type if exists input_params_type cascade;
create type input_params_type as
(
	height numeric(8,2),
	temperature numeric(8,2),
	pressure numeric(8,2),
	wind_direction numeric(8,2),
	wind_speed numeric(8,2),
	bullet_demolition_range numeric(8,2)
);

drop type if exists check_result_type cascade;
create type check_result_type as
(
	is_check boolean,
	error_message text,
	params input_params_type
);

drop type if exists calc_result_type cascade;
create type calc_result_type as
(

	measurement_type_id integer,

	height integer,

	deltaPressure numeric(8,2),

	deltaTemperature numeric(8,2),

	deviationTemperature numeric(8,2),

	deviationWind numeric(8,2),

	deviationWindDirection numeric(8,2)
);

DROP TYPE IF EXISTS public.calc_result_response_type;
CREATE TYPE public.calc_result_response_type AS (
    header VARCHAR(100),
    calc_result public.calc_result_type[]

	deviationTemperature numeric(8,2),

	deviationWind numeric(8,2),

	deviationWindDirection numeric(8,2)
);

create sequence calc_correction_types_seq;
create table calc_correction_types
(
	id integer not null primary key default nextval('public.calc_correction_types_seq'),
	parent_id integer,
	measurment_type_id integer,
	description text not null,
	values integer[]
);

insert into calc_correction_types(  description, values)
values( 'Таблица 2', array[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),	
( 'Таблица 3, скорость среднего ветра', null), 
( 'Таблица 3, направление среднего ветра', null);	

insert into calc_correction_types( description, parent_id, measurment_type_id, values)
values
('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), 
('Таблица 3, Направление среднего ветра (ВР)',3, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), 
('Таблица 3,Скорость среднего ветра (ДМК)',2, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), 
('Таблица 3, Направление среднего ветра (ДМК)',3, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]); 

insert into calc_correction_types( description, parent_id)
values('Таблица 2, Положительные температуры', 1 ), 
('Таблица 2, Отрицательные температуры', 1 ) 
;

create sequence calc_corrections_height_seq;
create table calc_corrections_height
(
	id integer primary key not null default nextval('public.calc_corrections_height_seq'),
	height integer not null
);

insert into calc_corrections_height(height)
values(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);

create sequence calc_corrections_seq;
create table calc_corrections
(
	id integer not null primary key default nextval('public.calc_corrections_seq'),
	calc_height_id integer not null,
	calc_correction_type_id integer not null,
	values integer[]
);

insert into calc_corrections(calc_height_id, calc_correction_type_id, values )

values(1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), 
(2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -39, -48]), 
(3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), 
(4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), 

(1, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), 
(2, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), 
(3, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), 
(4, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), 

(1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), 
(2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ,15]), 
(3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15 ,16]), 
(4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15 ,15, 16]), 

(1, 5, array[0]), 
(2, 5, array[1]), 
(3, 5, array[2]), 
(4, 5, array[2]), 

(1, 6, array[4,6,8,9,10,12,14,15,16,18,20,21,22]), 
(2, 6, array[5,7,10,11,12,14,17,18,20,22,23,25,27]), 
(3, 6, array[5,8,10,11,13,15,18,19,21,23,25,27,28]), 
(4, 6, array[5,8,11,12,13,16,19,20,23,24,26,28,30]), 

(1, 7, array[1]), 
(2, 7, array[2]), 
(3, 7, array[3]), 
(4, 7, array[3]) 
;

CREATE SEQUENCE IF NOT EXISTS temp_input_params_seq;
CREATE TABLE IF NOT EXISTS temp_input_params (
    id INTEGER NOT NULL PRIMARY KEY DEFAULT nextval('public.temp_input_params_seq'),
    emploee_name VARCHAR(100),
    measurment_type_id INTEGER NOT NULL,
    height NUMERIC(8,2) DEFAULT 0,
    temperature NUMERIC(8,2) DEFAULT 0,
    pressure NUMERIC(8,2) DEFAULT 0,
    wind_direction NUMERIC(8,2) DEFAULT 0,
    wind_speed NUMERIC(8,2) DEFAULT 0,
    bullet_demolition_range NUMERIC(8,2) DEFAULT 0,
    measurment_input_params_id INTEGER,
    error_message TEXT,
    calc_result JSONB
);

raise notice 'Расчетные структуры сформированы';

begin 

	alter table public.measurment_baths
	add constraint emploee_id_fk 
	foreign key (emploee_id)
	references public.employees (id);

	alter table public.measurment_baths
	add constraint measurment_input_param_id_fk 
	foreign key(measurment_input_param_id)
	references public.measurment_input_params(id);

	alter table public.measurment_input_params
	add constraint measurment_type_id_fk
	foreign key(measurment_type_id)
	references public.measurment_types (id);

	alter table public.employees
	add constraint military_rank_id_fk
	foreign key(military_rank_id)
	references public.military_ranks (id);

	alter table public.calc_correction_types
	add constraint calc_correction_types_measurment_type_id_fk
	foreign key(measurment_type_id)
	references public.measurment_types(id);

	alter table public.calc_corrections
	add constraint calc_corrections_calc_height_id_fk
	foreign key(calc_height_id)
	references public.calc_corrections_height(id);

	alter table public.calc_corrections
	add constraint calc_corrections_calc_correction_type_id_fk
	foreign key(calc_correction_type_id)
	references public.calc_correction_types(id);

	alter table public.calc_correction_types
	add constraint calc_correction_types_parent_id_fk
	foreign key(parent_id)
	references public.calc_correction_types(id);

end;

raise notice 'Связи сформированы';
raise notice 'Формируем индексы';

create index if not exists ix_measurment_baths_emploee_id on public.measurment_baths(emploee_id);
create index if not exists ix_measurment_baths_measurment_input_param_id on public.measurment_baths(measurment_input_param_id);

raise notice 'Индексы сформирован';

drop function if exists   public.fn_calc_header_temperature;
create function public.fn_calc_header_temperature(
	par_temperature numeric(8,2))
    returns numeric(8,2)
    language 'plpgsql'
as $BODY$
declare
	default_temperature numeric(8,2) default 15.9;
	default_temperature_key character varying default 'calc_table_temperature' ;
	virtual_temperature numeric(8,2) default 0;
	deltaTv numeric(8,2) default 0;
	var_result numeric(8,2) default 0;
begin	

	raise notice 'Расчет отклонения приземной виртуальной температуры по температуре %', par_temperature;

	Select coalesce(value::numeric(8,2), default_temperature) 
	from public.measurment_settings 
	into virtual_temperature
	where 
		key = default_temperature_key;

	deltaTv := par_temperature + 
		public.fn_calc_temperature_interpolation(par_temperature => par_temperature);

	var_result := deltaTv - virtual_temperature;

	return var_result;
end;
$BODY$;

drop function if exists public.fn_calc_header_period;
create function public.fn_calc_header_period(
	par_period timestamp with time zone)
    returns text
    language 'sql'
return  

		case when (extract(day from par_period) < 10::numeric) then '0'::text else ''::text end || 
		extract(day from par_period)::text || 

		case when (extract(hour from par_period) < 10::numeric) then '0'::text else ''::text end || 
		extract(hour from par_period)::text || 

		case when (extract(minute from par_period) < 10::numeric) then '0'::text
				else 
					left(extract(minute from par_period)::text, 1) 
		end;

drop function if exists public.fn_calc_header_pressure;
create function public.fn_calc_header_pressure
(
	par_pressure numeric(8,2))
	returns numeric(8,2)
	language 'plpgsql'
as $body$
declare
	default_pressure numeric(8,2) default 750;
	table_pressure numeric(8,2) default null;
	default_pressure_key character varying default 'calc_table_pressure' ;
begin

	raise notice 'Расчет отклонения наземного давления для %', par_pressure;

	if not exists (select 1 from public.measurment_settings where key = default_pressure_key ) then
	Begin
		table_pressure :=  default_pressure;
	end;
	else
	begin
		select value::numeric(18,2) 
		into table_pressure
		from  public.measurment_settings where key = default_pressure_key;
	end;
	end if;

	return par_pressure - coalesce(table_pressure,table_pressure) ;

end;
$body$;

drop function if exists public.fn_check_input_params(numeric(8,2), numeric(8,2),   numeric(8,2), numeric(8,2), numeric(8,2), numeric(8,2));
create function public.fn_check_input_params(
	par_height numeric,
	par_temperature numeric,
	par_pressure numeric,
	par_wind_direction numeric,
	par_wind_speed numeric,
	par_bullet_demolition_range numeric)
    returns check_result_type
    language 'plpgsql'
as $body$
declare
	var_result public.check_result_type;
begin
	var_result.is_check := False;

	if not exists (
		select 1 from (
				select 
						coalesce(min_temperature , '0')::numeric(8,2) as min_temperature, 
						coalesce(max_temperature, '0')::numeric(8,2) as max_temperature
				from 
				(select 1 ) as t
					cross join
					( select value as  min_temperature from public.measurment_settings where key = 'min_temperature' ) as t1
					cross join 
					( select value as  max_temperature from public.measurment_settings where key = 'max_temperature' ) as t2
				) as t	
			where
				par_temperature between min_temperature and max_temperature
			) then

			var_result.error_message := format('Температура % не укладывает в диаппазон!', par_temperature);
	end if;

	var_result.params.temperature := par_temperature;

	if not exists (
		select 1 from (
			select 
					coalesce(min_pressure , '0')::numeric(8,2) as min_pressure, 
					coalesce(max_pressure, '0')::numeric(8,2) as max_pressure
			from 
			(select 1 ) as t
				cross join
				( select value as  min_pressure from public.measurment_settings where key = 'min_pressure' ) as t1
				cross join 
				( select value as  max_pressure from public.measurment_settings where key = 'max_pressure' ) as t2
			) as t	
			where
				par_pressure between min_pressure and max_pressure
				) then

			var_result.error_message := format('Давление %s не укладывает в диаппазон!', par_pressure);
	end if;

	var_result.params.pressure := par_pressure;			

		if not exists (
			select 1 from (
				select 
						coalesce(min_height , '0')::numeric(8,2) as min_height, 
						coalesce(max_height, '0')::numeric(8,2) as  max_height
				from 
				(select 1 ) as t
					cross join
					( select value as  min_height from public.measurment_settings where key = 'min_height' ) as t1
					cross join 
					( select value as  max_height from public.measurment_settings where key = 'max_height' ) as t2
				) as t	
				where
				par_height between min_height and max_height
				) then

				var_result.error_message := format('Высота  %s не укладывает в диаппазон!', par_height);
		end if;

		var_result.params.height := par_height;

		if not exists (
			select 1 from (	
				select 
						coalesce(min_wind_direction , '0')::numeric(8,2) as min_wind_direction, 
						coalesce(max_wind_direction, '0')::numeric(8,2) as max_wind_direction
				from 
				(select 1 ) as t
					cross join
					( select value as  min_wind_direction from public.measurment_settings where key = 'min_wind_direction' ) as t1
					cross join 
					( select value as  max_wind_direction from public.measurment_settings where key = 'max_wind_direction' ) as t2
			)
				where
					par_wind_direction between min_wind_direction and max_wind_direction
			) then

			var_result.error_message := format('Направление ветра %s не укладывает в диаппазон!', par_wind_direction);
	end if;

	var_result.params.wind_direction := par_wind_direction;	
	var_result.params.wind_speed := par_wind_speed;

	if coalesce(var_result.error_message,'') = ''  then
		var_result.is_check = True;
	end if;	

	return var_result;

end;
$body$;

drop function if exists public.fn_check_input_params(input_params);
create function public.fn_check_input_params(
	par_param input_params_type
)
returns public.input_params_type
language 'plpgsql'
as $body$
declare
	var_result check_result_type;
begin

	var_result := fn_check_input_params(
		par_param.height, par_param.temperature, par_param.pressure, par_param.wind_direction,
		par_param.wind_speed, par_param.bullet_demolition_range
	);

	if var_result.is_check = False then
		raise exception 'Ошибка %', var_result.error_message;
	end if;

	return var_result.params;
end ;
$body$;

drop function if exists public.fn_calc_interpolation;
create function public.fn_calc_interpolation(
	par_temperature numeric,
	par_interpolation public.interpolation_type
	)
	returns numeric
	language 'plpgsql'
as $body$

declare 
     var_result numeric(8,2) default 0;
     var_denominator numeric(8,2) default 0;
begin
     var_denominator := par_interpolation.x1 - par_interpolation.x0;
     if var_denominator = 0.0 then
            raise exception 'Деление на нуль. Возможно, некорректные данные в таблице с поправками!';
     end if;

	var_result := (par_temperature - par_interpolation.x0) * (par_interpolation.y1 - par_interpolation.y0) / var_denominator + par_interpolation.y0;
	return var_result;
end;
$body$;

drop function if exists public.fn_calc_temperature_interpolation;
create function public.fn_calc_temperature_interpolation(
		par_temperature numeric(8,2))
		returns numeric
		language 'plpgsql'
as $body$
	declare 
			var_interpolation interpolation_type;
	        var_result numeric(8,2) default 0;
	        var_min_temparure numeric(8,2) default 0;
	        var_max_temperature numeric(8,2) default 0;
	        var_denominator numeric(8,2) default 0;
	begin

  				raise notice 'Расчет интерполяции для температуры %', par_temperature;

                if exists (select 1 from public.calc_corrections_temperature where temperature = par_temperature ) then
                begin
                        select correction 
                        into  var_result 
                        from  public.calc_corrections_temperature
                        where 
                                temperature = par_temperature;
                end;
                else    
                begin

                        select min(temperature), max(temperature) 
                        into var_min_temparure, var_max_temperature
                        from public.calc_corrections_temperature;

                        if par_temperature < var_min_temparure or   
                           par_temperature > var_max_temperature then

                                raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диаппазон: %, %',
                                        var_min_temparure, var_max_temperature;
                        end if;   

                        select x0, y0, x1, y1 
						 into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
                        from
                        (
                                select t1.temperature as x0, t1.correction as y0
                                from public.calc_corrections_temperature as t1
                                where t1.temperature <= par_temperature
                                order by t1.temperature desc
                                limit 1
                        ) as leftPart
                        cross join
                        (
                                select t1.temperature as x1, t1.correction as y1
                                from public.calc_corrections_temperature as t1
                                where t1.temperature >= par_temperature
                                order by t1.temperature 
                                limit 1
                        ) as rightPart;

                        raise notice 'Граничные значения %', var_interpolation;

						 var_result :=  fn_calc_interpolation( par_temperature,  var_interpolation);

                end;
                end if;

				return var_result;

end;
$body$;

drop function if exists fn_get_random_timestamp;
create function fn_get_random_timestamp(
	par_min_value timestamp,
	par_max_value timestamp)
returns timestamp
language 'plpgsql'
as $body$
begin
	 return random() * (par_max_value - par_min_value) + par_min_value;
end;
$body$;

drop function if exists fn_get_randon_integer;
create function fn_get_randon_integer(
	par_min_value integer,
	par_max_value integer
	)
returns integer
language 'plpgsql'
as $body$
begin
	return floor((par_max_value + 1 - par_min_value)*random())::integer + par_min_value;
end;
$body$;

drop function if exists fn_get_random_text;
create function fn_get_random_text(
   par_length int,
   par_list_of_chars text DEFAULT 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюяABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_0123456789'
)
returns text
language 'plpgsql'
as $body$
declare
    var_len_of_list integer default length(par_list_of_chars);
    var_position integer;
    var_result text = '';
	var_random_number integer;
	var_max_value integer;
	var_min_value integer;
begin

	var_min_value := 10;
	var_max_value := 50;

    for var_position in 1 .. par_length loop

	    var_random_number := fn_get_randon_integer(var_min_value, var_max_value );
        var_result := var_result || substr(par_list_of_chars,  var_random_number ,1);
    end loop;

    return var_result;

end;
$body$;

drop function if exists fn_calc_header_meteo_avg;
create function fn_calc_header_meteo_avg(
	par_params input_params_type
)
returns text
language 'plpgsql'
as $body$
declare
	var_result text;
	var_params input_params_type;
begin

	var_params := public.fn_check_input_params(par_params);

	select

		public.fn_calc_header_period(now()) ||

	    lpad( 340::text, 4, '0' ) ||

		lpad(
				case when coalesce(var_params.pressure,0) < 0 then
					'5' 
				else ''
				end ||
				lpad ( abs(( coalesce(var_params.pressure, 0) )::int)::text,2,'0')
			, 3, '0') as "БББ",

		lpad( 
				case when coalesce( var_params.temperature, 0) < 0 then
					'5'
				else
					''
				end ||
				( coalesce(var_params.temperature,0)::int)::text
			, 2,'0')
		into 	var_result;
	return 	var_result;

end;
$body$;

raise notice 'Структура сформирована успешно';
end $$;

CREATE OR REPLACE FUNCTION fn_tr_temp_input_params()
RETURNS TRIGGER AS $$
DECLARE 
    var_check_result public.check_result_type;
    var_input_params public.input_params_type;
    var_response public.calc_result_response_type;
    var_calc_result public.calc_result_type[];
    var_emploee_id integer;
BEGIN
    var_check_result := fn_check_input_params(
        NEW.height,
        NEW.temperature,
        NEW.pressure,
        NEW.wind_direction,
        NEW.wind_speed,
        NEW.bullet_demolition_range
    );

    IF var_check_result.is_check = FALSE THEN
        NEW.error_message := var_check_result.error_message;
        RETURN NEW;
    END IF;

    var_input_params := var_check_result.params;

    SELECT id INTO var_emploee_id
    FROM public.employees
    WHERE name = NEW.emploee_name;

    IF var_emploee_id IS NULL THEN
        INSERT INTO public.employees (name, military_rank_id)
        VALUES (NEW.emploee_name, 1)
        RETURNING id INTO var_emploee_id;
    END IF;

    var_response.header := public.fn_calc_header_meteo_avg(var_input_params);

    CALL public.sp_calc_corrections(
        par_input_params => var_input_params,
        par_measurement_type_id => NEW.measurment_type_id,
        par_results => var_calc_result
    );

    var_response.calc_result := var_calc_result;
    NEW.calc_result := row_to_json(var_response);

    INSERT INTO public.measurment_input_params (
        measurment_type_id, height, temperature, pressure, wind_direction, wind_speed, bullet_demolition_range
    ) VALUES (
        NEW.measurment_type_id, NEW.height, NEW.temperature, NEW.pressure, NEW.wind_direction, NEW.wind_speed, NEW.bullet_demolition_range
    ) RETURNING id INTO NEW.measurment_input_params_id;

    INSERT INTO public.measurment_baths (emploee_id, measurment_input_param_id, started)
    VALUES (var_emploee_id, NEW.measurment_input_params_id, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_temp_input_params
BEFORE INSERT ON temp_input_params
FOR EACH ROW
EXECUTE FUNCTION fn_tr_temp_input_params();

do $$
declare
	var_pressure_value numeric(8,2) default 0;
	var_temperature_value numeric(8,2) default 0;

	var_period text;
	var_pressure text;
	var_height text;
	var_temperature text;
begin

	var_pressure_value :=  round(public.fn_calc_header_pressure(743));
	var_temperature_value := round( public.fn_calc_header_temperature(3));

	select

		public.fn_calc_header_period(now()) as "ДДЧЧМ",

	    lpad( 340::text, 4, '0' ) as "ВВВВ",

		lpad(
				case when var_pressure_value < 0 then
					'5' 
				else ''
				end ||
				lpad ( abs((var_pressure_value)::int)::text,2,'0')
			, 3, '0') as "БББ",

		lpad( 
				case when var_temperature_value < 0 then
					'5'
				else
					''
				end ||
				(abs(var_temperature_value)::int)::text
			, 2,'0') as "TT"
		into
			var_period, var_height, var_pressure, var_temperature;

		raise notice '==============================';
		raise notice 'Пример расчета метео приближенный';
		raise notice 'ДДЧЧМ %, ВВВВ %,  БББ % , TT %', 	var_period, var_height, var_pressure, var_temperature;

end $$;

do $$
declare 
	var_result public.check_result_type;
begin

	raise notice '=====================================';
	raise notice 'Проверка работы функции [fn_check_input_params]';
	raise notice 'Положительный сценарий';

	var_result := public.fn_check_input_params(par_height => 400, par_temperature => 23, par_pressure => 740, par_wind_direction => 5, par_wind_speed => 5, par_bullet_demolition_range => 5 );

	if var_result.is_check != True then
		raise notice '-> Проверка не пройдена!';
	else
		raise notice '-> Проверка пройдена';
	end if;

	raise notice 'Сообщени: %', var_result.error_message;

	var_result := public.fn_check_input_params(par_height => -400, par_temperature => 23, par_pressure => 740, par_wind_direction => 5, par_wind_speed => 5, par_bullet_demolition_range => 5 );
	raise notice 'Отрицательный сценарий';

	if var_result.is_check != False then
		raise notice '-> Проверка не пройдена!';
	else
		raise notice '-> Проверка пройдена';
	end if;

	raise notice 'Сообщение: %', var_result.error_message;

	raise notice '=====================================';

end $$;

do $$
declare
	 var_position integer;
	 var_emploee_ids integer[];
	 var_emploee_quantity integer default 5;
	 var_min_rank integer;
	 var_max_rank integer;
	 var_emploee_id integer;
	 var_current_emploee_id integer;
	 var_index integer;
	 var_measure_type_id integer;
	 var_measure_input_data_id integer;
begin

	select min(id), max(id) 
	into var_min_rank,var_max_rank
	from public.military_ranks;

	for var_position in 1 .. var_emploee_quantity loop
		insert into public.employees(name, birthday, military_rank_id )
		select 
			fn_get_random_text(25),								
			fn_get_random_timestamp('1978-01-01','2000-01-01'), 				
			fn_get_randon_integer(var_min_rank, var_max_rank)  
			;
		select id into var_emploee_id from public.employees order by id desc limit 1;	
		var_emploee_ids := var_emploee_ids || var_emploee_id;
	end loop;

	raise notice 'Сформированы тестовые пользователи  %', var_emploee_ids;

	foreach var_current_emploee_id in ARRAY var_emploee_ids LOOP
		for var_index in 1 .. 100 loop
			var_measure_type_id := fn_get_randon_integer(1,2);

			insert into public.measurment_input_params(measurment_type_id, height, temperature, pressure, wind_direction, wind_speed)
			select
				var_measure_type_id,
				fn_get_randon_integer(0,600)::numeric(8,2), 
				fn_get_randon_integer(0, 50)::numeric(8,2), 
				fn_get_randon_integer(500, 850)::numeric(8,2), 
				fn_get_randon_integer(0,59)::numeric(8,2), 
				fn_get_randon_integer(0,59)::numeric(8,2)	
				;

			select id into var_measure_input_data_id from 	measurment_input_params order by id desc limit 1;

			insert into public.measurment_baths( emploee_id, measurment_input_param_id, started)
			select
				var_current_emploee_id,
				var_measure_input_data_id,
				fn_get_random_timestamp('2025-02-01 00:00', '2025-02-05 00:00')
			;	
		end loop;

	end loop;

	raise notice 'Набор тестовых данных сформирован успешно';

end $$;

create  view vw_report_fails_statistics
as

with emploee_cte as
(

		select 
			t1.id , t1.name as user_name, t2.description as position
			from public.employees as t1
			inner join public.military_ranks as t2 on t1.military_rank_id = t2.id
),
measurements_cte as
(

		select count(*) as quantity,  emploee_id 
		from public.measurment_input_params as t1
		inner join public.measurment_baths as t2 on t2.measurment_input_param_id = t1.id
		group by emploee_id
), 
fails_cte as
(

		select 
			count(*) as quantity_fails,
			emploee_id 
		from public.measurment_input_params as t1
		inner join public.measurment_baths as t2 on t2.measurment_input_param_id = t1.id
		where
			(public.fn_check_input_params(height, temperature, pressure, wind_direction, wind_speed, bullet_demolition_range)::public.check_result_type).is_check = False
		group by emploee_id
)

select 
	user_name, position, coalesce(quantity,0) as quantity, coalesce(quantity_fails,0) as quantity_fails
from emploee_cte as t1
left join measurements_cte as t2 on t1.id = t2.emploee_id
left join fails_cte as t3 on t1.id = t3.emploee_id
order by coalesce(quantity_fails,0) desc;

create view vw_report_fails_height_statistics
as

with emploee_cte as
(

		select 
			t1.id , t1.name as user_name, t2.description as position
			from public.employees as t1
			inner join public.military_ranks as t2 on t1.military_rank_id = t2.id
),
measurements_cte as
(

		select count(*) as quantity,  emploee_id 
		from public.measurment_input_params as t1
		inner join public.measurment_baths as t2 on t2.measurment_input_param_id = t1.id
		group by emploee_id
), 
fails_cte as
(

		select 
			count(*) as quantity_fails,
			emploee_id 
		from public.measurment_input_params as t1
		inner join public.measurment_baths as t2 on t2.measurment_input_param_id = t1.id
		where
			(public.fn_check_input_params(height, temperature, pressure, wind_direction, wind_speed, bullet_demolition_range)::public.check_result_type).is_check = False
		group by emploee_id
),
measurments_height_cte as
(

		select min(height) as min_height, max(height) as max_height,  emploee_id 
		from public.measurment_input_params as t1
		inner join public.measurment_baths as t2 on t2.measurment_input_param_id = t1.id
		group by emploee_id
)

select 
	user_name, position, coalesce(quantity,0) as quantity, coalesce(quantity_fails,0) as quantity_fails, 
		coalesce(min_height, 0) as min_height, coalesce(max_height, 0) as max_height 
from emploee_cte as t1
left join measurements_cte as t2 on t1.id = t2.emploee_id
left join fails_cte as t3 on t1.id = t3.emploee_id
left join measurments_height_cte as t4 on t1.id = t4.emploee_id
order by coalesce(quantity_fails,0) asc, coalesce(min_height, 0) asc ;

drop procedure if exists sp_calc_corrections;
create procedure public.sp_calc_corrections(
	in par_input_params input_params_type,
	in par_measurement_type_id integer,
	inout par_results calc_result_type[]
	)
language 'plpgsql'
as $body$
declare
	var_header integer[];
	var_values integer[];
	var_result calc_result_type;
	var_correction_type_id integer;

	var_rec_height record;
	var_index integer;
	var_left_index integer;
	var_right_index integer;
	var_left_value integer;
	var_right_value integer;

	var_interpolation interpolation_type;

	var_table2_positive_values integer default 7;

	var_table2_negative_values integer default 8;

	var_table2_header integer default 1;

	var_table3_wind_speed integer default 2;

	var_table3_wind_direction integer default 3;

begin

	par_input_params.height := 400;
	par_input_params.temperature := 24;
	par_input_params.pressure := 700;
	par_input_params.wind_direction := 10;
	par_input_params.wind_speed := 40;
	par_input_params.bullet_demolition_range := 6;

	if not exists (select 1 from public.measurment_types where id = par_measurement_type_id) then
		raise exception 'Некорректно указан тип оборудования по коду %', par_measurement_type_id;
	end if;

	raise notice 'Расчет для оборудования %, параметры %', par_measurement_type_id,par_input_params;
	par_input_params := public.fn_check_input_params(par_param => par_input_params);
	raise notice 'Проверка входных параметров пройдена';

	for var_rec_height in
		select * from public.calc_corrections_height  loop

		var_result.deltapressure := 0;
		var_result.deltatemperature := 0;
		var_result.deviationtemperature := 0;
		var_result.deviationwind := 0;
		var_result.deviationwinddirection := 0;

		var_result.height := var_rec_height.height;

		var_result.measurement_type_id := par_measurement_type_id;

		var_result.deltapressure := public.fn_calc_header_pressure( par_input_params.pressure);

		var_result.deltatemperature := public.fn_calc_header_temperature(par_input_params.temperature);

		var_header := (select values from public.calc_correction_types where id = var_table2_header );

		var_values := 
			case when var_result.deltatemperature >= 0 then

				(select values from public.calc_corrections
					where calc_correction_type_id = var_table2_positive_values
					and calc_height_id = var_rec_height.id limit 1)
			else

				(select values from public.calc_corrections
					where calc_correction_type_id = var_table2_negative_values
					and calc_height_id = var_rec_height.id limit 1)
			end;	

		if var_values is null then

			continue;
		end if;	

		select max(position)
		into var_left_index 
		from unnest(var_header) as position
		where position <= var_result.deltatemperature;

		select min(position)
		into var_right_index
		from unnest(var_header) as position
		where position > var_result.deltatemperature;

		var_left_value := var_values[ var_left_index ];
		var_right_value := var_values[ var_right_index ];

		var_interpolation.x0 := var_left_index;
		var_interpolation.x1 := var_right_index;
		var_interpolation.y0 := var_left_value;
		var_interpolation.y1 := var_right_value;

		var_result.deviationtemperature := 
			round(fn_calc_interpolation( var_result.deltatemperature, var_interpolation));

		select id 
		into var_correction_type_id
		from calc_correction_types where
				measurment_type_id = par_measurement_type_id and parent_id = var_table3_wind_speed ;

		var_header := (select values from public.calc_correction_types 
					where measurment_type_id = par_measurement_type_id and parent_id = var_table3_wind_speed );
		var_values := (select values from calc_corrections
					where calc_correction_type_id = var_correction_type_id
					and calc_height_id = var_rec_height.id limit 1);

		select 
			coalesce(min(position), 1) from 	
		into var_index
		unnest(var_header) as position
		where position > round(par_input_params.wind_speed);

		var_result.deviationwind := var_values[var_index]	;

		select id 
		into var_correction_type_id
		from calc_correction_types where
				measurment_type_id = par_measurement_type_id and parent_id = var_table3_wind_direction ;

		var_values := (select values from calc_corrections
					where calc_correction_type_id = var_correction_type_id
					and calc_height_id = var_rec_height.id limit 1);

		select 
			position 
		into var_result.deviationwinddirection
		from
			unnest(var_values) as position
		limit 1;		

		par_results := array_append(par_results, var_result);

	end loop;	

	raise notice 'Расчет поправок завершен успешно';

end;
$body$;

select * from vw_report_fails_height_statistics
