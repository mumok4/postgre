SELECT 
    e.name AS "ФИО",
    mr.description AS "Должность",
    COUNT(mb.id) AS "Кол-во измерений",
    SUM(
        CASE 
            WHEN mip.temperature < (SELECT value::numeric FROM public.measurment_settings WHERE key = 'min_temperature') 
                 OR mip.temperature > (SELECT value::numeric FROM public.measurment_settings WHERE key = 'max_temperature')
                 OR mip.pressure < (SELECT value::numeric FROM public.measurment_settings WHERE key = 'min_pressure') 
                 OR mip.pressure > (SELECT value::numeric FROM public.measurment_settings WHERE key = 'max_pressure')
                 OR mip.height < (SELECT value::numeric FROM public.measurment_settings WHERE key = 'min_height') 
                 OR mip.height > (SELECT value::numeric FROM public.measurment_settings WHERE key = 'max_height')
                 OR mip.wind_direction < (SELECT value::numeric FROM public.measurment_settings WHERE key = 'min_wind_direction') 
                 OR mip.wind_direction > (SELECT value::numeric FROM public.measurment_settings WHERE key = 'max_wind_direction')
            THEN 1 
            ELSE 0 
        END
    ) AS "Количество ошибочных данных"
FROM 
    public.measurment_baths as mb
    INNER JOIN public.measurment_input_params as mip ON mb.measurment_input_param_id = mip.id
    INNER JOIN public.employees as e ON mb.emploee_id = e.id
    INNER JOIN public.military_ranks as mr ON e.military_rank_id = mr.id
GROUP BY 
    e.name, mr.description
ORDER BY 
    "Количество ошибочных данных" DESC;