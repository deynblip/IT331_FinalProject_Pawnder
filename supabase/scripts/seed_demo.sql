-- =====================================================================
-- PAWNDER: DEMO SEED
-- =====================================================================

do $$
declare
  -- ====== BAGUHIN ======
  v_owner_email  text := 'EMAIL_NG_DEMO_OWNER@gmail.com';
  v_helper_email text := 'EMAIL_NG_DEMO_HELPER@gmail.com';
  v_admin_email  text := 'admin@pawnder.com';

  v_r1 text := 'demo/report-1.jpg';
  v_r2 text := 'demo/report-2.jpg';
  v_r3 text := 'demo/report-3.jpg';
  v_r4 text := 'demo/report-4.jpg';
  v_r5 text := 'demo/report-5.jpg';
  v_p1 text := 'demo/pet-1.jpg';
  v_p2 text := 'demo/pet-2.jpg';
  v_p3 text := 'demo/pet-3.jpg';
  v_p4 text := 'demo/pet-4.jpg';
  v_p5 text := 'demo/pet-5.jpg';
  -- =========================

  v_owner  uuid;
  v_helper uuid;
  v_admin  uuid;
  v_id     uuid;
begin
  select id into v_owner  from auth.users where email = v_owner_email;
  select id into v_helper from auth.users where email = v_helper_email;
  select id into v_admin  from auth.users where email = v_admin_email;

  if v_owner is null then
    raise exception 'Walang account na may email na %. Gumawa muna sa app.', v_owner_email;
  end if;
  if v_helper is null then
    raise exception 'Walang account na may email na %. Gumawa muna sa app.', v_helper_email;
  end if;
  if v_owner = v_helper then
    raise exception 'Dapat magkaiba ang owner at helper.';
  end if;

  if exists (select 1 from public.stray_reports where photo_paths[1] like 'demo/%' and removed_at is null) then
    raise exception 'May demo data na. Patakbuhin muna ang hide_demo.sql kung gusto mong ulitin.';
  end if;

  -- ---------------------------------------------------------------
  -- STRAY REPORTS
  -- ---------------------------------------------------------------

  -- 1. Needs Rescue, Urgent (dog, may sugat)
  insert into public.stray_reports
    (reporter_id, animal_type, urgency, description, photo_paths,
     latitude, longitude, address, created_at)
  values
    (v_owner, 'Dog', 'urgent',
     'Brown stray dog limping and bleeding on one hind leg. Hiding under a parked tricycle near the public market. Looks scared but not aggressive.',
     array[v_r1], 13.7565, 121.0583,
     'Near Batangas City Public Market, Poblacion, Batangas City',
     now() - interval '2 hours');

  -- 2. Needs Rescue, Needs Help (3 kuting)
  insert into public.stray_reports
    (reporter_id, animal_type, urgency, description, photo_paths,
     latitude, longitude, address, created_at)
  values
    (v_helper, 'Cat', 'needs_help',
     'Three kittens (about 3 weeks old) in a cardboard box beside the road. The mother cat is nowhere to be seen. They need milk and a safe place.',
     array[v_r2], 13.7867, 121.0728,
     'Alangilan, Batangas City',
     now() - interval '5 hours');

  -- 3. Needs Rescue, Sighted (asong gala, baka nawawalang alaga)
  insert into public.stray_reports
    (reporter_id, animal_type, urgency, description, photo_paths,
     latitude, longitude, address, possibly_lost_pet, created_at)
  values
    (v_owner, 'Dog', 'sighted',
     'White and brown dog wandering near the school gate for two days now. Wears a faded blue collar and is very friendly, so it may be someone''s lost pet.',
     array[v_r3], 13.7648, 121.0572,
     'Pallocan West, Batangas City',
     true, now() - interval '1 day');

  -- 4. In Progress (may aktibong responder)
  insert into public.stray_reports
    (reporter_id, animal_type, urgency, description, photo_paths,
     latitude, longitude, address, rescue_status, created_at)
  values
    (v_owner, 'Dog', 'urgent',
     'Thin black dog lying near the roadside, very weak and not moving much. Cars pass by quickly. Someone please help before it gets hit.',
     array[v_r4], 13.7500, 121.0536,
     'Kumintang Ibaba, Batangas City',
     'in_progress', now() - interval '3 hours')
  returning id into v_id;

  insert into public.rescue_responses
    (report_id, responder_id, role, state, joined_at, last_update_at)
  values
    (v_id, v_helper, 'lead', 'active',
     now() - interval '1 hour', now() - interval '30 minutes');

  -- 5. Rescued (tapos na)
  insert into public.stray_reports
    (reporter_id, animal_type, urgency, description, photo_paths,
     latitude, longitude, address, rescue_status, outcome,
     closed_by, closed_at, created_at)
  values
    (v_owner, 'Cat', 'needs_help',
     'Orange cat stuck on top of a concrete wall, meowing the whole night. Looked hungry and a bit injured.',
     array[v_r5], 13.7452, 121.0634,
     'Sta. Rita Karsada, Batangas City',
     'rescued', 'brought_to_vet_shelter',
     v_helper, now() - interval '1 day', now() - interval '3 days')
  returning id into v_id;

  insert into public.rescue_responses
    (report_id, responder_id, role, state, outcome,
     checked_in_at, joined_at, last_update_at, ended_at)
  values
    (v_id, v_helper, 'lead', 'finished', 'brought_to_vet_shelter',
     now() - interval '2 days 22 hours', now() - interval '2 days 23 hours',
     now() - interval '1 day', now() - interval '1 day');

  -- ---------------------------------------------------------------
  -- ADOPTION POSTS (4 Approved, 1 Pending para ma-approve ng admin live)
  -- ---------------------------------------------------------------

  -- Pet 1: Approved, Dog, rescued stray (owner)
  insert into public.adoption_posts
    (poster_id, name, animal_type, age_text, sex, source, description,
     health_info, reason, barangay, city, province, photo_paths,
     status, reviewed_by, reviewed_at, created_at)
  values
    (v_owner, 'Brownie', 'Dog', '2 years', 'Male', 'rescued_stray',
     'Gentle and playful aspin rescued from the roadside. Good with kids and other dogs. Already knows how to sit and shake paws.',
     'Dewormed and vaccinated. Neutered.',
     'We rescued him but cannot keep him because our house is too small.',
     'Alangilan', 'Batangas City', 'Batangas', array[v_p1],
     'approved', v_admin, now() - interval '2 days', now() - interval '3 days')
  returning id into v_id;
  insert into public.adoption_post_contacts
    (post_id, street, contact_person, contact_phone, contact_email)
  values
    (v_id, 'Rizal Ave.', 'Demo Owner', '0917 123 4567', v_owner_email);

  -- Pet 2: Approved, Cat, rehoming (owner)
  insert into public.adoption_posts
    (poster_id, name, animal_type, age_text, sex, source, description,
     health_info, reason, barangay, city, province, photo_paths,
     status, reviewed_by, reviewed_at, created_at)
  values
    (v_owner, 'Mimi', 'Cat', '1 year', 'Female', 'rehoming',
     'Calm and affectionate calico cat. Litter trained and loves to nap on laps. Best for a quiet home.',
     'Vaccinated. Spayed.',
     'Our family is moving abroad and cannot bring her along.',
     'Pallocan West', 'Batangas City', 'Batangas', array[v_p3],
     'approved', v_admin, now() - interval '1 day', now() - interval '2 days')
  returning id into v_id;
  insert into public.adoption_post_contacts
    (post_id, street, contact_person, contact_phone, contact_email)
  values
    (v_id, 'P. Burgos St.', 'Demo Owner', '0917 123 4567', v_owner_email);

  -- Pet 3: Approved, Dog, rescued stray (helper)
  insert into public.adoption_posts
    (poster_id, name, animal_type, age_text, sex, source, description,
     health_info, reason, barangay, city, province, photo_paths,
     status, reviewed_by, reviewed_at, created_at)
  values
    (v_helper, 'Coco', 'Dog', '8 months', 'Female', 'rescued_stray',
     'Energetic puppy found near the highway. Loves to run and fetch. Needs a family with a yard or time for daily walks.',
     'First vaccine done. Needs the next shots in 2 weeks.',
     'We have too many rescued dogs at home and want her to find a loving family.',
     'Kumintang Ibaba', 'Batangas City', 'Batangas', array[v_p2],
     'approved', v_admin, now() - interval '1 day', now() - interval '2 days')
  returning id into v_id;
  insert into public.adoption_post_contacts
    (post_id, street, contact_person, contact_phone, contact_email)
  values
    (v_id, 'Pastor Ave.', 'Demo Helper', '0918 765 4321', v_helper_email);

  -- Pet 4: Approved, Cat, rescued stray (helper)
  insert into public.adoption_posts
    (poster_id, name, animal_type, age_text, sex, source, description,
     health_info, reason, barangay, city, province, photo_paths,
     status, reviewed_by, reviewed_at, created_at)
  values
    (v_helper, 'Orange', 'Cat', '6 months', 'Male', 'rescued_stray',
     'Cheerful orange kitten rescued from a wall. Very vocal and friendly. Gets along with other cats.',
     'Dewormed. Ready for his first vaccine.',
     'Rescued last week and now ready for a permanent home.',
     'Sta. Rita Karsada', 'Batangas City', 'Batangas', array[v_p4],
     'approved', v_admin, now() - interval '12 hours', now() - interval '1 day')
  returning id into v_id;
  insert into public.adoption_post_contacts
    (post_id, street, contact_person, contact_phone, contact_email)
  values
    (v_id, 'J.P. Laurel Hwy.', 'Demo Helper', '0918 765 4321', v_helper_email);

  -- Pet 5: PENDING (para i-approve ng admin habang nagde-demo)
  insert into public.adoption_posts
    (poster_id, name, animal_type, age_text, sex, source, description,
     health_info, reason, barangay, city, province, photo_paths,
     status, created_at)
  values
    (v_helper, 'Bruno', 'Dog', '3 years', 'Male', 'rehoming',
     'Loyal and well-trained dog. Knows basic commands and is good on a leash. Needs an experienced owner who can give him daily exercise.',
     'Fully vaccinated. Neutered.',
     'Our work schedule changed and we can no longer give him the time he needs.',
     'Alangilan', 'Batangas City', 'Batangas', array[v_p5],
     'pending', now() - interval '1 hour')
  returning id into v_id;
  insert into public.adoption_post_contacts
    (post_id, street, contact_person, contact_phone, contact_email)
  values
    (v_id, 'Rizal Ave.', 'Demo Helper', '0918 765 4321', v_helper_email);

  raise notice 'Tapos! 5 stray reports at 5 adoption posts ang nagawa.';
end $$;

-- Check: dapat 5 at 5 ang lumabas.
select
  (select count(*) from public.stray_reports  where photo_paths[1] like 'demo/%' and removed_at is null) as demo_reports,
  (select count(*) from public.adoption_posts where photo_paths[1] like 'demo/%' and removed_at is null) as demo_pets;
