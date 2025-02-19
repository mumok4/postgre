DO $$
DECLARE
   v_post_id uuid;
   user_id uuid;
   device_id uuid;
   i integer;
   j integer;
BEGIN
   INSERT INTO public.posts (name)
   VALUES ('Метеостанция №1');
   
   v_post_id := (SELECT id FROM public.posts WHERE name = 'Метеостанция №1');

   INSERT INTO public.devices (name)
   VALUES ('Метеорологический датчик №1');
   
   device_id := (SELECT id FROM public.devices WHERE name = 'Метеорологический датчик №1');

   INSERT INTO public.users (post_id, fullname, age)
   VALUES 
       (v_post_id, 'Иванов Иван Иванович', 35),
       (v_post_id, 'Петров Петр Петрович', 42),
       (v_post_id, 'Сидоров Сидор Сидорович', 28);

   FOR i IN 1..3 LOOP
       SELECT id INTO user_id 
       FROM public.users u
       WHERE u.post_id = v_post_id
       ORDER BY id
       OFFSET i-1 LIMIT 1;
       
       FOR j IN 1..100 LOOP
           PERFORM public.insert_measurement(
               (random() * 1000)::numeric(8,2),
               ((random() * 116) - 58)::numeric(8,2),
               ((random() * 400) + 500)::numeric(8,2),
               (random() * 100)::numeric(8,2),
               (random() * 59)::numeric(8,2),
               user_id,
               device_id,
               ((random() * 90) - 45)::numeric(4,2),
               ((random() * 99) - 49.5)::numeric(4,2)
           );
       END LOOP;
   END LOOP;

END$$;

SELECT * FROM public.measurements LIMIT 10