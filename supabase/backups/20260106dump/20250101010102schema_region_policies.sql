CREATE POLICY "region_centraleast_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_centraleast_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_centraleast_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_centraleast_reader" USING (("olp_region" = 'central_east'::"text"));
CREATE POLICY "region_centraleast_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_centraleast_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_centraleast_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_centraleast_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_centralnorth_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_centralnorth_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_centralnorth_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_centralnorth_reader" USING (("olp_region" = 'central_north'::"text"));
CREATE POLICY "region_centralnorth_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_centralnorth_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_centralnorth_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_centralnorth_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_centralwest_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_centralwest_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_centralwest_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_centralwest_reader" USING (("olp_region" = 'central_west'::"text"));
CREATE POLICY "region_centralwest_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_centralwest_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_centralwest_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_centralwest_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_east_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_east_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_east_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_east_reader" USING (("olp_region" = 'east'::"text"));
CREATE POLICY "region_east_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_east_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_east_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_east_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_north_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_north_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_north_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_north_reader" USING (("olp_region" = 'north'::"text"));
CREATE POLICY "region_north_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_north_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_north_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_north_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_southcentral_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_southcentral_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_southcentral_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_southcentral_reader" USING (("olp_region" = 'south_central'::"text"));
CREATE POLICY "region_southcentral_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_southcentral_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_southcentral_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_southcentral_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_southwest_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_southwest_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_southwest_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_southwest_reader" USING (("olp_region" = 'south_west'::"text"));
CREATE POLICY "region_southwest_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_southwest_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_southwest_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_southwest_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_torontoede_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_torontoede_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_torontoede_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_torontoede_reader" USING (("olp_region" = 'toronto_ede'::"text"));
CREATE POLICY "region_torontoede_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_torontoede_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_torontoede_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_torontoede_writer" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_torontoyns_reader_contact_read" ON "public"."contact" FOR SELECT TO "region_torontoyns_reader" USING ((EXISTS ( SELECT 1
CREATE POLICY "region_torontoyns_reader_division_read" ON "public"."division_electoral_district" FOR SELECT TO "region_torontoyns_reader" USING (("olp_region" = 'toronto_yns'::"text"));
CREATE POLICY "region_torontoyns_writer_contact_insert" ON "public"."contact" FOR INSERT TO "region_torontoyns_writer" WITH CHECK ((EXISTS ( SELECT 1
CREATE POLICY "region_torontoyns_writer_contact_update" ON "public"."contact" FOR UPDATE TO "region_torontoyns_writer" USING ((EXISTS ( SELECT 1
