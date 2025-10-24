-- ================================================
-- Auto-generated SQL: create riding and region roles with RLS
-- ================================================

-- === Riding: Ajax ===
CREATE ROLE riding_ajax_reader LOGIN PASSWORD 'CJ+gEk!Xg(_5dRpMb6zd';
CREATE ROLE riding_ajax_writer LOGIN PASSWORD 'CJ+gEk!Xg(_5dRpMb6zd' INHERIT;
GRANT riding_ajax_reader TO riding_ajax_writer;

CREATE POLICY riding_ajax_reader_read ON public.contact FOR SELECT TO riding_ajax_reader USING (division_electoral_district = 'Ajax');
CREATE POLICY riding_ajax_writer_insert ON public.contact FOR INSERT TO riding_ajax_writer WITH CHECK (division_electoral_district = 'Ajax');
CREATE POLICY riding_ajax_writer_update ON public.contact FOR UPDATE TO riding_ajax_writer USING (division_electoral_district = 'Ajax') WITH CHECK (division_electoral_district = 'Ajax');

GRANT SELECT ON public.contact TO riding_ajax_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_ajax_writer;

-- === Riding: Algoma—Manitoulin ===
CREATE ROLE riding_algomamanitoulin_reader LOGIN PASSWORD 'rwPObO2R7OTUu8seN8mn';
CREATE ROLE riding_algomamanitoulin_writer LOGIN PASSWORD 'rwPObO2R7OTUu8seN8mn' INHERIT;
GRANT riding_algomamanitoulin_reader TO riding_algomamanitoulin_writer;

CREATE POLICY riding_algomamanitoulin_reader_read ON public.contact FOR SELECT TO riding_algomamanitoulin_reader USING (division_electoral_district = 'Algoma—Manitoulin');
CREATE POLICY riding_algomamanitoulin_writer_insert ON public.contact FOR INSERT TO riding_algomamanitoulin_writer WITH CHECK (division_electoral_district = 'Algoma—Manitoulin');
CREATE POLICY riding_algomamanitoulin_writer_update ON public.contact FOR UPDATE TO riding_algomamanitoulin_writer USING (division_electoral_district = 'Algoma—Manitoulin') WITH CHECK (division_electoral_district = 'Algoma—Manitoulin');

GRANT SELECT ON public.contact TO riding_algomamanitoulin_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_algomamanitoulin_writer;

-- === Riding: Aurora—Oak Ridges—Richmond Hill ===
CREATE ROLE riding_auroraoakridgesrichmondhill_reader LOGIN PASSWORD '8X1=Z(oGFTY)4DoWqoZ8';
CREATE ROLE riding_auroraoakridgesrichmondhill_writer LOGIN PASSWORD '8X1=Z(oGFTY)4DoWqoZ8' INHERIT;
GRANT riding_auroraoakridgesrichmondhill_reader TO riding_auroraoakridgesrichmondhill_writer;

CREATE POLICY riding_auroraoakridgesrichmondhill_reader_read ON public.contact FOR SELECT TO riding_auroraoakridgesrichmondhill_reader USING (division_electoral_district = 'Aurora—Oak Ridges—Richmond Hill');
CREATE POLICY riding_auroraoakridgesrichmondhill_writer_insert ON public.contact FOR INSERT TO riding_auroraoakridgesrichmondhill_writer WITH CHECK (division_electoral_district = 'Aurora—Oak Ridges—Richmond Hill');
CREATE POLICY riding_auroraoakridgesrichmondhill_writer_update ON public.contact FOR UPDATE TO riding_auroraoakridgesrichmondhill_writer USING (division_electoral_district = 'Aurora—Oak Ridges—Richmond Hill') WITH CHECK (division_electoral_district = 'Aurora—Oak Ridges—Richmond Hill');

GRANT SELECT ON public.contact TO riding_auroraoakridgesrichmondhill_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_auroraoakridgesrichmondhill_writer;

-- === Riding: Barrie—Innisfil ===
CREATE ROLE riding_barrieinnisfil_reader LOGIN PASSWORD '0NfWanh%&toXbp(QR(ix';
CREATE ROLE riding_barrieinnisfil_writer LOGIN PASSWORD '0NfWanh%&toXbp(QR(ix' INHERIT;
GRANT riding_barrieinnisfil_reader TO riding_barrieinnisfil_writer;

CREATE POLICY riding_barrieinnisfil_reader_read ON public.contact FOR SELECT TO riding_barrieinnisfil_reader USING (division_electoral_district = 'Barrie—Innisfil');
CREATE POLICY riding_barrieinnisfil_writer_insert ON public.contact FOR INSERT TO riding_barrieinnisfil_writer WITH CHECK (division_electoral_district = 'Barrie—Innisfil');
CREATE POLICY riding_barrieinnisfil_writer_update ON public.contact FOR UPDATE TO riding_barrieinnisfil_writer USING (division_electoral_district = 'Barrie—Innisfil') WITH CHECK (division_electoral_district = 'Barrie—Innisfil');

GRANT SELECT ON public.contact TO riding_barrieinnisfil_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_barrieinnisfil_writer;

-- === Riding: Barrie—Springwater—Oro-Medonte ===
CREATE ROLE riding_barriespringwateroromedonte_reader LOGIN PASSWORD 'Q(Oc=%CpeiENz#w-nmF@';
CREATE ROLE riding_barriespringwateroromedonte_writer LOGIN PASSWORD 'Q(Oc=%CpeiENz#w-nmF@' INHERIT;
GRANT riding_barriespringwateroromedonte_reader TO riding_barriespringwateroromedonte_writer;

CREATE POLICY riding_barriespringwateroromedonte_reader_read ON public.contact FOR SELECT TO riding_barriespringwateroromedonte_reader USING (division_electoral_district = 'Barrie—Springwater—Oro-Medonte');
CREATE POLICY riding_barriespringwateroromedonte_writer_insert ON public.contact FOR INSERT TO riding_barriespringwateroromedonte_writer WITH CHECK (division_electoral_district = 'Barrie—Springwater—Oro-Medonte');
CREATE POLICY riding_barriespringwateroromedonte_writer_update ON public.contact FOR UPDATE TO riding_barriespringwateroromedonte_writer USING (division_electoral_district = 'Barrie—Springwater—Oro-Medonte') WITH CHECK (division_electoral_district = 'Barrie—Springwater—Oro-Medonte');

GRANT SELECT ON public.contact TO riding_barriespringwateroromedonte_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_barriespringwateroromedonte_writer;

-- === Riding: Bay of Quinte ===
CREATE ROLE riding_bayofquinte_reader LOGIN PASSWORD 'A$+_H58+hsb7F7rJ16oe';
CREATE ROLE riding_bayofquinte_writer LOGIN PASSWORD 'A$+_H58+hsb7F7rJ16oe' INHERIT;
GRANT riding_bayofquinte_reader TO riding_bayofquinte_writer;

CREATE POLICY riding_bayofquinte_reader_read ON public.contact FOR SELECT TO riding_bayofquinte_reader USING (division_electoral_district = 'Bay of Quinte');
CREATE POLICY riding_bayofquinte_writer_insert ON public.contact FOR INSERT TO riding_bayofquinte_writer WITH CHECK (division_electoral_district = 'Bay of Quinte');
CREATE POLICY riding_bayofquinte_writer_update ON public.contact FOR UPDATE TO riding_bayofquinte_writer USING (division_electoral_district = 'Bay of Quinte') WITH CHECK (division_electoral_district = 'Bay of Quinte');

GRANT SELECT ON public.contact TO riding_bayofquinte_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_bayofquinte_writer;

-- === Riding: Beaches—East York ===
CREATE ROLE riding_beacheseastyork_reader LOGIN PASSWORD 'aCPFtrs%Qn92J&U3LzkP';
CREATE ROLE riding_beacheseastyork_writer LOGIN PASSWORD 'aCPFtrs%Qn92J&U3LzkP' INHERIT;
GRANT riding_beacheseastyork_reader TO riding_beacheseastyork_writer;

CREATE POLICY riding_beacheseastyork_reader_read ON public.contact FOR SELECT TO riding_beacheseastyork_reader USING (division_electoral_district = 'Beaches—East York');
CREATE POLICY riding_beacheseastyork_writer_insert ON public.contact FOR INSERT TO riding_beacheseastyork_writer WITH CHECK (division_electoral_district = 'Beaches—East York');
CREATE POLICY riding_beacheseastyork_writer_update ON public.contact FOR UPDATE TO riding_beacheseastyork_writer USING (division_electoral_district = 'Beaches—East York') WITH CHECK (division_electoral_district = 'Beaches—East York');

GRANT SELECT ON public.contact TO riding_beacheseastyork_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_beacheseastyork_writer;

-- === Riding: Brampton Centre ===
CREATE ROLE riding_bramptoncentre_reader LOGIN PASSWORD 'gEqiwyHnn-y3UTEZisJ-';
CREATE ROLE riding_bramptoncentre_writer LOGIN PASSWORD 'gEqiwyHnn-y3UTEZisJ-' INHERIT;
GRANT riding_bramptoncentre_reader TO riding_bramptoncentre_writer;

CREATE POLICY riding_bramptoncentre_reader_read ON public.contact FOR SELECT TO riding_bramptoncentre_reader USING (division_electoral_district = 'Brampton Centre');
CREATE POLICY riding_bramptoncentre_writer_insert ON public.contact FOR INSERT TO riding_bramptoncentre_writer WITH CHECK (division_electoral_district = 'Brampton Centre');
CREATE POLICY riding_bramptoncentre_writer_update ON public.contact FOR UPDATE TO riding_bramptoncentre_writer USING (division_electoral_district = 'Brampton Centre') WITH CHECK (division_electoral_district = 'Brampton Centre');

GRANT SELECT ON public.contact TO riding_bramptoncentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_bramptoncentre_writer;

-- === Riding: Brampton East ===
CREATE ROLE riding_bramptoneast_reader LOGIN PASSWORD 'yJa5w0L*7g3V5VOyRMv0';
CREATE ROLE riding_bramptoneast_writer LOGIN PASSWORD 'yJa5w0L*7g3V5VOyRMv0' INHERIT;
GRANT riding_bramptoneast_reader TO riding_bramptoneast_writer;

CREATE POLICY riding_bramptoneast_reader_read ON public.contact FOR SELECT TO riding_bramptoneast_reader USING (division_electoral_district = 'Brampton East');
CREATE POLICY riding_bramptoneast_writer_insert ON public.contact FOR INSERT TO riding_bramptoneast_writer WITH CHECK (division_electoral_district = 'Brampton East');
CREATE POLICY riding_bramptoneast_writer_update ON public.contact FOR UPDATE TO riding_bramptoneast_writer USING (division_electoral_district = 'Brampton East') WITH CHECK (division_electoral_district = 'Brampton East');

GRANT SELECT ON public.contact TO riding_bramptoneast_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_bramptoneast_writer;

-- === Riding: Brampton North ===
CREATE ROLE riding_bramptonnorth_reader LOGIN PASSWORD 'Tqr=XGXU932(9cT4HxIy';
CREATE ROLE riding_bramptonnorth_writer LOGIN PASSWORD 'Tqr=XGXU932(9cT4HxIy' INHERIT;
GRANT riding_bramptonnorth_reader TO riding_bramptonnorth_writer;

CREATE POLICY riding_bramptonnorth_reader_read ON public.contact FOR SELECT TO riding_bramptonnorth_reader USING (division_electoral_district = 'Brampton North');
CREATE POLICY riding_bramptonnorth_writer_insert ON public.contact FOR INSERT TO riding_bramptonnorth_writer WITH CHECK (division_electoral_district = 'Brampton North');
CREATE POLICY riding_bramptonnorth_writer_update ON public.contact FOR UPDATE TO riding_bramptonnorth_writer USING (division_electoral_district = 'Brampton North') WITH CHECK (division_electoral_district = 'Brampton North');

GRANT SELECT ON public.contact TO riding_bramptonnorth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_bramptonnorth_writer;

-- === Riding: Brampton South ===
CREATE ROLE riding_bramptonsouth_reader LOGIN PASSWORD 'hvKY!uu3ZGB4Uw8$(Vf#';
CREATE ROLE riding_bramptonsouth_writer LOGIN PASSWORD 'hvKY!uu3ZGB4Uw8$(Vf#' INHERIT;
GRANT riding_bramptonsouth_reader TO riding_bramptonsouth_writer;

CREATE POLICY riding_bramptonsouth_reader_read ON public.contact FOR SELECT TO riding_bramptonsouth_reader USING (division_electoral_district = 'Brampton South');
CREATE POLICY riding_bramptonsouth_writer_insert ON public.contact FOR INSERT TO riding_bramptonsouth_writer WITH CHECK (division_electoral_district = 'Brampton South');
CREATE POLICY riding_bramptonsouth_writer_update ON public.contact FOR UPDATE TO riding_bramptonsouth_writer USING (division_electoral_district = 'Brampton South') WITH CHECK (division_electoral_district = 'Brampton South');

GRANT SELECT ON public.contact TO riding_bramptonsouth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_bramptonsouth_writer;

-- === Riding: Brampton West ===
CREATE ROLE riding_bramptonwest_reader LOGIN PASSWORD 'L=82$4($eobq5n-Yf)pd';
CREATE ROLE riding_bramptonwest_writer LOGIN PASSWORD 'L=82$4($eobq5n-Yf)pd' INHERIT;
GRANT riding_bramptonwest_reader TO riding_bramptonwest_writer;

CREATE POLICY riding_bramptonwest_reader_read ON public.contact FOR SELECT TO riding_bramptonwest_reader USING (division_electoral_district = 'Brampton West');
CREATE POLICY riding_bramptonwest_writer_insert ON public.contact FOR INSERT TO riding_bramptonwest_writer WITH CHECK (division_electoral_district = 'Brampton West');
CREATE POLICY riding_bramptonwest_writer_update ON public.contact FOR UPDATE TO riding_bramptonwest_writer USING (division_electoral_district = 'Brampton West') WITH CHECK (division_electoral_district = 'Brampton West');

GRANT SELECT ON public.contact TO riding_bramptonwest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_bramptonwest_writer;

-- === Riding: Brantford—Brant ===
CREATE ROLE riding_brantfordbrant_reader LOGIN PASSWORD 'N=7I!=KsIx+EpG9DIGXa';
CREATE ROLE riding_brantfordbrant_writer LOGIN PASSWORD 'N=7I!=KsIx+EpG9DIGXa' INHERIT;
GRANT riding_brantfordbrant_reader TO riding_brantfordbrant_writer;

CREATE POLICY riding_brantfordbrant_reader_read ON public.contact FOR SELECT TO riding_brantfordbrant_reader USING (division_electoral_district = 'Brantford—Brant');
CREATE POLICY riding_brantfordbrant_writer_insert ON public.contact FOR INSERT TO riding_brantfordbrant_writer WITH CHECK (division_electoral_district = 'Brantford—Brant');
CREATE POLICY riding_brantfordbrant_writer_update ON public.contact FOR UPDATE TO riding_brantfordbrant_writer USING (division_electoral_district = 'Brantford—Brant') WITH CHECK (division_electoral_district = 'Brantford—Brant');

GRANT SELECT ON public.contact TO riding_brantfordbrant_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_brantfordbrant_writer;

-- === Riding: Bruce—Grey—Owen Sound ===
CREATE ROLE riding_brucegreyowensound_reader LOGIN PASSWORD 'Qv4MEJpMpLCf-@4N)+!z';
CREATE ROLE riding_brucegreyowensound_writer LOGIN PASSWORD 'Qv4MEJpMpLCf-@4N)+!z' INHERIT;
GRANT riding_brucegreyowensound_reader TO riding_brucegreyowensound_writer;

CREATE POLICY riding_brucegreyowensound_reader_read ON public.contact FOR SELECT TO riding_brucegreyowensound_reader USING (division_electoral_district = 'Bruce—Grey—Owen Sound');
CREATE POLICY riding_brucegreyowensound_writer_insert ON public.contact FOR INSERT TO riding_brucegreyowensound_writer WITH CHECK (division_electoral_district = 'Bruce—Grey—Owen Sound');
CREATE POLICY riding_brucegreyowensound_writer_update ON public.contact FOR UPDATE TO riding_brucegreyowensound_writer USING (division_electoral_district = 'Bruce—Grey—Owen Sound') WITH CHECK (division_electoral_district = 'Bruce—Grey—Owen Sound');

GRANT SELECT ON public.contact TO riding_brucegreyowensound_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_brucegreyowensound_writer;

-- === Riding: Burlington ===
CREATE ROLE riding_burlington_reader LOGIN PASSWORD '(dZ#$tAI3-IH5dmW0V4E';
CREATE ROLE riding_burlington_writer LOGIN PASSWORD '(dZ#$tAI3-IH5dmW0V4E' INHERIT;
GRANT riding_burlington_reader TO riding_burlington_writer;

CREATE POLICY riding_burlington_reader_read ON public.contact FOR SELECT TO riding_burlington_reader USING (division_electoral_district = 'Burlington');
CREATE POLICY riding_burlington_writer_insert ON public.contact FOR INSERT TO riding_burlington_writer WITH CHECK (division_electoral_district = 'Burlington');
CREATE POLICY riding_burlington_writer_update ON public.contact FOR UPDATE TO riding_burlington_writer USING (division_electoral_district = 'Burlington') WITH CHECK (division_electoral_district = 'Burlington');

GRANT SELECT ON public.contact TO riding_burlington_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_burlington_writer;

-- === Riding: Cambridge ===
CREATE ROLE riding_cambridge_reader LOGIN PASSWORD '=&YB2QPXKyJz!j7domT2';
CREATE ROLE riding_cambridge_writer LOGIN PASSWORD '=&YB2QPXKyJz!j7domT2' INHERIT;
GRANT riding_cambridge_reader TO riding_cambridge_writer;

CREATE POLICY riding_cambridge_reader_read ON public.contact FOR SELECT TO riding_cambridge_reader USING (division_electoral_district = 'Cambridge');
CREATE POLICY riding_cambridge_writer_insert ON public.contact FOR INSERT TO riding_cambridge_writer WITH CHECK (division_electoral_district = 'Cambridge');
CREATE POLICY riding_cambridge_writer_update ON public.contact FOR UPDATE TO riding_cambridge_writer USING (division_electoral_district = 'Cambridge') WITH CHECK (division_electoral_district = 'Cambridge');

GRANT SELECT ON public.contact TO riding_cambridge_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_cambridge_writer;

-- === Riding: Carleton ===
CREATE ROLE riding_carleton_reader LOGIN PASSWORD '(Y952ejNn===769B&xW1';
CREATE ROLE riding_carleton_writer LOGIN PASSWORD '(Y952ejNn===769B&xW1' INHERIT;
GRANT riding_carleton_reader TO riding_carleton_writer;

CREATE POLICY riding_carleton_reader_read ON public.contact FOR SELECT TO riding_carleton_reader USING (division_electoral_district = 'Carleton');
CREATE POLICY riding_carleton_writer_insert ON public.contact FOR INSERT TO riding_carleton_writer WITH CHECK (division_electoral_district = 'Carleton');
CREATE POLICY riding_carleton_writer_update ON public.contact FOR UPDATE TO riding_carleton_writer USING (division_electoral_district = 'Carleton') WITH CHECK (division_electoral_district = 'Carleton');

GRANT SELECT ON public.contact TO riding_carleton_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_carleton_writer;

-- === Riding: Chatham-Kent—Leamington ===
CREATE ROLE riding_chathamkentleamington_reader LOGIN PASSWORD 'fNlA&GZToybK2DsX46P$';
CREATE ROLE riding_chathamkentleamington_writer LOGIN PASSWORD 'fNlA&GZToybK2DsX46P$' INHERIT;
GRANT riding_chathamkentleamington_reader TO riding_chathamkentleamington_writer;

CREATE POLICY riding_chathamkentleamington_reader_read ON public.contact FOR SELECT TO riding_chathamkentleamington_reader USING (division_electoral_district = 'Chatham-Kent—Leamington');
CREATE POLICY riding_chathamkentleamington_writer_insert ON public.contact FOR INSERT TO riding_chathamkentleamington_writer WITH CHECK (division_electoral_district = 'Chatham-Kent—Leamington');
CREATE POLICY riding_chathamkentleamington_writer_update ON public.contact FOR UPDATE TO riding_chathamkentleamington_writer USING (division_electoral_district = 'Chatham-Kent—Leamington') WITH CHECK (division_electoral_district = 'Chatham-Kent—Leamington');

GRANT SELECT ON public.contact TO riding_chathamkentleamington_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_chathamkentleamington_writer;

-- === Riding: Davenport ===
CREATE ROLE riding_davenport_reader LOGIN PASSWORD '#g-vm&UkYub4KBPojoR6';
CREATE ROLE riding_davenport_writer LOGIN PASSWORD '#g-vm&UkYub4KBPojoR6' INHERIT;
GRANT riding_davenport_reader TO riding_davenport_writer;

CREATE POLICY riding_davenport_reader_read ON public.contact FOR SELECT TO riding_davenport_reader USING (division_electoral_district = 'Davenport');
CREATE POLICY riding_davenport_writer_insert ON public.contact FOR INSERT TO riding_davenport_writer WITH CHECK (division_electoral_district = 'Davenport');
CREATE POLICY riding_davenport_writer_update ON public.contact FOR UPDATE TO riding_davenport_writer USING (division_electoral_district = 'Davenport') WITH CHECK (division_electoral_district = 'Davenport');

GRANT SELECT ON public.contact TO riding_davenport_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_davenport_writer;

-- === Riding: Don Valley East ===
CREATE ROLE riding_donvalleyeast_reader LOGIN PASSWORD ')_#G-bFM-OtRfYdoevpY';
CREATE ROLE riding_donvalleyeast_writer LOGIN PASSWORD ')_#G-bFM-OtRfYdoevpY' INHERIT;
GRANT riding_donvalleyeast_reader TO riding_donvalleyeast_writer;

CREATE POLICY riding_donvalleyeast_reader_read ON public.contact FOR SELECT TO riding_donvalleyeast_reader USING (division_electoral_district = 'Don Valley East');
CREATE POLICY riding_donvalleyeast_writer_insert ON public.contact FOR INSERT TO riding_donvalleyeast_writer WITH CHECK (division_electoral_district = 'Don Valley East');
CREATE POLICY riding_donvalleyeast_writer_update ON public.contact FOR UPDATE TO riding_donvalleyeast_writer USING (division_electoral_district = 'Don Valley East') WITH CHECK (division_electoral_district = 'Don Valley East');

GRANT SELECT ON public.contact TO riding_donvalleyeast_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_donvalleyeast_writer;

-- === Riding: Don Valley North ===
CREATE ROLE riding_donvalleynorth_reader LOGIN PASSWORD '^7A*4rFTPX5+0v8We^z0';
CREATE ROLE riding_donvalleynorth_writer LOGIN PASSWORD '^7A*4rFTPX5+0v8We^z0' INHERIT;
GRANT riding_donvalleynorth_reader TO riding_donvalleynorth_writer;

CREATE POLICY riding_donvalleynorth_reader_read ON public.contact FOR SELECT TO riding_donvalleynorth_reader USING (division_electoral_district = 'Don Valley North');
CREATE POLICY riding_donvalleynorth_writer_insert ON public.contact FOR INSERT TO riding_donvalleynorth_writer WITH CHECK (division_electoral_district = 'Don Valley North');
CREATE POLICY riding_donvalleynorth_writer_update ON public.contact FOR UPDATE TO riding_donvalleynorth_writer USING (division_electoral_district = 'Don Valley North') WITH CHECK (division_electoral_district = 'Don Valley North');

GRANT SELECT ON public.contact TO riding_donvalleynorth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_donvalleynorth_writer;

-- === Riding: Don Valley West ===
CREATE ROLE riding_donvalleywest_reader LOGIN PASSWORD '$!XRlw+htyWdG7@7lPE#';
CREATE ROLE riding_donvalleywest_writer LOGIN PASSWORD '$!XRlw+htyWdG7@7lPE#' INHERIT;
GRANT riding_donvalleywest_reader TO riding_donvalleywest_writer;

CREATE POLICY riding_donvalleywest_reader_read ON public.contact FOR SELECT TO riding_donvalleywest_reader USING (division_electoral_district = 'Don Valley West');
CREATE POLICY riding_donvalleywest_writer_insert ON public.contact FOR INSERT TO riding_donvalleywest_writer WITH CHECK (division_electoral_district = 'Don Valley West');
CREATE POLICY riding_donvalleywest_writer_update ON public.contact FOR UPDATE TO riding_donvalleywest_writer USING (division_electoral_district = 'Don Valley West') WITH CHECK (division_electoral_district = 'Don Valley West');

GRANT SELECT ON public.contact TO riding_donvalleywest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_donvalleywest_writer;

-- === Riding: Dufferin—Caledon ===
CREATE ROLE riding_dufferincaledon_reader LOGIN PASSWORD 'Ol#-LVKic9ly6)gPIHW$';
CREATE ROLE riding_dufferincaledon_writer LOGIN PASSWORD 'Ol#-LVKic9ly6)gPIHW$' INHERIT;
GRANT riding_dufferincaledon_reader TO riding_dufferincaledon_writer;

CREATE POLICY riding_dufferincaledon_reader_read ON public.contact FOR SELECT TO riding_dufferincaledon_reader USING (division_electoral_district = 'Dufferin—Caledon');
CREATE POLICY riding_dufferincaledon_writer_insert ON public.contact FOR INSERT TO riding_dufferincaledon_writer WITH CHECK (division_electoral_district = 'Dufferin—Caledon');
CREATE POLICY riding_dufferincaledon_writer_update ON public.contact FOR UPDATE TO riding_dufferincaledon_writer USING (division_electoral_district = 'Dufferin—Caledon') WITH CHECK (division_electoral_district = 'Dufferin—Caledon');

GRANT SELECT ON public.contact TO riding_dufferincaledon_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_dufferincaledon_writer;

-- === Riding: Durham ===
CREATE ROLE riding_durham_reader LOGIN PASSWORD 'EI@LPPN%71dA8^GVtNg%';
CREATE ROLE riding_durham_writer LOGIN PASSWORD 'EI@LPPN%71dA8^GVtNg%' INHERIT;
GRANT riding_durham_reader TO riding_durham_writer;

CREATE POLICY riding_durham_reader_read ON public.contact FOR SELECT TO riding_durham_reader USING (division_electoral_district = 'Durham');
CREATE POLICY riding_durham_writer_insert ON public.contact FOR INSERT TO riding_durham_writer WITH CHECK (division_electoral_district = 'Durham');
CREATE POLICY riding_durham_writer_update ON public.contact FOR UPDATE TO riding_durham_writer USING (division_electoral_district = 'Durham') WITH CHECK (division_electoral_district = 'Durham');

GRANT SELECT ON public.contact TO riding_durham_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_durham_writer;

-- === Riding: Eglinton—Lawrence ===
CREATE ROLE riding_eglintonlawrence_reader LOGIN PASSWORD '0Wn_wxb%B)zIVewRx$#p';
CREATE ROLE riding_eglintonlawrence_writer LOGIN PASSWORD '0Wn_wxb%B)zIVewRx$#p' INHERIT;
GRANT riding_eglintonlawrence_reader TO riding_eglintonlawrence_writer;

CREATE POLICY riding_eglintonlawrence_reader_read ON public.contact FOR SELECT TO riding_eglintonlawrence_reader USING (division_electoral_district = 'Eglinton—Lawrence');
CREATE POLICY riding_eglintonlawrence_writer_insert ON public.contact FOR INSERT TO riding_eglintonlawrence_writer WITH CHECK (division_electoral_district = 'Eglinton—Lawrence');
CREATE POLICY riding_eglintonlawrence_writer_update ON public.contact FOR UPDATE TO riding_eglintonlawrence_writer USING (division_electoral_district = 'Eglinton—Lawrence') WITH CHECK (division_electoral_district = 'Eglinton—Lawrence');

GRANT SELECT ON public.contact TO riding_eglintonlawrence_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_eglintonlawrence_writer;

-- === Riding: Elgin—Middlesex—London ===
CREATE ROLE riding_elginmiddlesexlondon_reader LOGIN PASSWORD 'LeJKs#AzxCOz^GCxXL+4';
CREATE ROLE riding_elginmiddlesexlondon_writer LOGIN PASSWORD 'LeJKs#AzxCOz^GCxXL+4' INHERIT;
GRANT riding_elginmiddlesexlondon_reader TO riding_elginmiddlesexlondon_writer;

CREATE POLICY riding_elginmiddlesexlondon_reader_read ON public.contact FOR SELECT TO riding_elginmiddlesexlondon_reader USING (division_electoral_district = 'Elgin—Middlesex—London');
CREATE POLICY riding_elginmiddlesexlondon_writer_insert ON public.contact FOR INSERT TO riding_elginmiddlesexlondon_writer WITH CHECK (division_electoral_district = 'Elgin—Middlesex—London');
CREATE POLICY riding_elginmiddlesexlondon_writer_update ON public.contact FOR UPDATE TO riding_elginmiddlesexlondon_writer USING (division_electoral_district = 'Elgin—Middlesex—London') WITH CHECK (division_electoral_district = 'Elgin—Middlesex—London');

GRANT SELECT ON public.contact TO riding_elginmiddlesexlondon_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_elginmiddlesexlondon_writer;

-- === Riding: Essex ===
CREATE ROLE riding_essex_reader LOGIN PASSWORD 'De18Azn*0(V1h3zai9hG';
CREATE ROLE riding_essex_writer LOGIN PASSWORD 'De18Azn*0(V1h3zai9hG' INHERIT;
GRANT riding_essex_reader TO riding_essex_writer;

CREATE POLICY riding_essex_reader_read ON public.contact FOR SELECT TO riding_essex_reader USING (division_electoral_district = 'Essex');
CREATE POLICY riding_essex_writer_insert ON public.contact FOR INSERT TO riding_essex_writer WITH CHECK (division_electoral_district = 'Essex');
CREATE POLICY riding_essex_writer_update ON public.contact FOR UPDATE TO riding_essex_writer USING (division_electoral_district = 'Essex') WITH CHECK (division_electoral_district = 'Essex');

GRANT SELECT ON public.contact TO riding_essex_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_essex_writer;

-- === Riding: Etobicoke Centre ===
CREATE ROLE riding_etobicokecentre_reader LOGIN PASSWORD 'fewg!R(xp*uWOpi&@6jh';
CREATE ROLE riding_etobicokecentre_writer LOGIN PASSWORD 'fewg!R(xp*uWOpi&@6jh' INHERIT;
GRANT riding_etobicokecentre_reader TO riding_etobicokecentre_writer;

CREATE POLICY riding_etobicokecentre_reader_read ON public.contact FOR SELECT TO riding_etobicokecentre_reader USING (division_electoral_district = 'Etobicoke Centre');
CREATE POLICY riding_etobicokecentre_writer_insert ON public.contact FOR INSERT TO riding_etobicokecentre_writer WITH CHECK (division_electoral_district = 'Etobicoke Centre');
CREATE POLICY riding_etobicokecentre_writer_update ON public.contact FOR UPDATE TO riding_etobicokecentre_writer USING (division_electoral_district = 'Etobicoke Centre') WITH CHECK (division_electoral_district = 'Etobicoke Centre');

GRANT SELECT ON public.contact TO riding_etobicokecentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_etobicokecentre_writer;

-- === Riding: Etobicoke North ===
CREATE ROLE riding_etobicokenorth_reader LOGIN PASSWORD 'EE!=Hn9WL*5uL&pIB%EH';
CREATE ROLE riding_etobicokenorth_writer LOGIN PASSWORD 'EE!=Hn9WL*5uL&pIB%EH' INHERIT;
GRANT riding_etobicokenorth_reader TO riding_etobicokenorth_writer;

CREATE POLICY riding_etobicokenorth_reader_read ON public.contact FOR SELECT TO riding_etobicokenorth_reader USING (division_electoral_district = 'Etobicoke North');
CREATE POLICY riding_etobicokenorth_writer_insert ON public.contact FOR INSERT TO riding_etobicokenorth_writer WITH CHECK (division_electoral_district = 'Etobicoke North');
CREATE POLICY riding_etobicokenorth_writer_update ON public.contact FOR UPDATE TO riding_etobicokenorth_writer USING (division_electoral_district = 'Etobicoke North') WITH CHECK (division_electoral_district = 'Etobicoke North');

GRANT SELECT ON public.contact TO riding_etobicokenorth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_etobicokenorth_writer;

-- === Riding: Etobicoke—Lakeshore ===
CREATE ROLE riding_etobicokelakeshore_reader LOGIN PASSWORD 'Hz=8&J*Yh*llgdOcK*@1';
CREATE ROLE riding_etobicokelakeshore_writer LOGIN PASSWORD 'Hz=8&J*Yh*llgdOcK*@1' INHERIT;
GRANT riding_etobicokelakeshore_reader TO riding_etobicokelakeshore_writer;

CREATE POLICY riding_etobicokelakeshore_reader_read ON public.contact FOR SELECT TO riding_etobicokelakeshore_reader USING (division_electoral_district = 'Etobicoke—Lakeshore');
CREATE POLICY riding_etobicokelakeshore_writer_insert ON public.contact FOR INSERT TO riding_etobicokelakeshore_writer WITH CHECK (division_electoral_district = 'Etobicoke—Lakeshore');
CREATE POLICY riding_etobicokelakeshore_writer_update ON public.contact FOR UPDATE TO riding_etobicokelakeshore_writer USING (division_electoral_district = 'Etobicoke—Lakeshore') WITH CHECK (division_electoral_district = 'Etobicoke—Lakeshore');

GRANT SELECT ON public.contact TO riding_etobicokelakeshore_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_etobicokelakeshore_writer;

-- === Riding: Flamborough—Glanbrook ===
CREATE ROLE riding_flamboroughglanbrook_reader LOGIN PASSWORD 'bKpfV3*y=wZt5kkcORJz';
CREATE ROLE riding_flamboroughglanbrook_writer LOGIN PASSWORD 'bKpfV3*y=wZt5kkcORJz' INHERIT;
GRANT riding_flamboroughglanbrook_reader TO riding_flamboroughglanbrook_writer;

CREATE POLICY riding_flamboroughglanbrook_reader_read ON public.contact FOR SELECT TO riding_flamboroughglanbrook_reader USING (division_electoral_district = 'Flamborough—Glanbrook');
CREATE POLICY riding_flamboroughglanbrook_writer_insert ON public.contact FOR INSERT TO riding_flamboroughglanbrook_writer WITH CHECK (division_electoral_district = 'Flamborough—Glanbrook');
CREATE POLICY riding_flamboroughglanbrook_writer_update ON public.contact FOR UPDATE TO riding_flamboroughglanbrook_writer USING (division_electoral_district = 'Flamborough—Glanbrook') WITH CHECK (division_electoral_district = 'Flamborough—Glanbrook');

GRANT SELECT ON public.contact TO riding_flamboroughglanbrook_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_flamboroughglanbrook_writer;

-- === Riding: Glengarry—Prescott—Russell ===
CREATE ROLE riding_glengarryprescottrussell_reader LOGIN PASSWORD 'Q-*tmnDkWEt%MJd7FmQO';
CREATE ROLE riding_glengarryprescottrussell_writer LOGIN PASSWORD 'Q-*tmnDkWEt%MJd7FmQO' INHERIT;
GRANT riding_glengarryprescottrussell_reader TO riding_glengarryprescottrussell_writer;

CREATE POLICY riding_glengarryprescottrussell_reader_read ON public.contact FOR SELECT TO riding_glengarryprescottrussell_reader USING (division_electoral_district = 'Glengarry—Prescott—Russell');
CREATE POLICY riding_glengarryprescottrussell_writer_insert ON public.contact FOR INSERT TO riding_glengarryprescottrussell_writer WITH CHECK (division_electoral_district = 'Glengarry—Prescott—Russell');
CREATE POLICY riding_glengarryprescottrussell_writer_update ON public.contact FOR UPDATE TO riding_glengarryprescottrussell_writer USING (division_electoral_district = 'Glengarry—Prescott—Russell') WITH CHECK (division_electoral_district = 'Glengarry—Prescott—Russell');

GRANT SELECT ON public.contact TO riding_glengarryprescottrussell_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_glengarryprescottrussell_writer;

-- === Riding: Guelph ===
CREATE ROLE riding_guelph_reader LOGIN PASSWORD 'a+SV5aG!aFO(xCvW3l$(';
CREATE ROLE riding_guelph_writer LOGIN PASSWORD 'a+SV5aG!aFO(xCvW3l$(' INHERIT;
GRANT riding_guelph_reader TO riding_guelph_writer;

CREATE POLICY riding_guelph_reader_read ON public.contact FOR SELECT TO riding_guelph_reader USING (division_electoral_district = 'Guelph');
CREATE POLICY riding_guelph_writer_insert ON public.contact FOR INSERT TO riding_guelph_writer WITH CHECK (division_electoral_district = 'Guelph');
CREATE POLICY riding_guelph_writer_update ON public.contact FOR UPDATE TO riding_guelph_writer USING (division_electoral_district = 'Guelph') WITH CHECK (division_electoral_district = 'Guelph');

GRANT SELECT ON public.contact TO riding_guelph_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_guelph_writer;

-- === Riding: Haldimand—Norfolk ===
CREATE ROLE riding_haldimandnorfolk_reader LOGIN PASSWORD 'IzNLlhRU9d6)W$_(FISP';
CREATE ROLE riding_haldimandnorfolk_writer LOGIN PASSWORD 'IzNLlhRU9d6)W$_(FISP' INHERIT;
GRANT riding_haldimandnorfolk_reader TO riding_haldimandnorfolk_writer;

CREATE POLICY riding_haldimandnorfolk_reader_read ON public.contact FOR SELECT TO riding_haldimandnorfolk_reader USING (division_electoral_district = 'Haldimand—Norfolk');
CREATE POLICY riding_haldimandnorfolk_writer_insert ON public.contact FOR INSERT TO riding_haldimandnorfolk_writer WITH CHECK (division_electoral_district = 'Haldimand—Norfolk');
CREATE POLICY riding_haldimandnorfolk_writer_update ON public.contact FOR UPDATE TO riding_haldimandnorfolk_writer USING (division_electoral_district = 'Haldimand—Norfolk') WITH CHECK (division_electoral_district = 'Haldimand—Norfolk');

GRANT SELECT ON public.contact TO riding_haldimandnorfolk_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_haldimandnorfolk_writer;

-- === Riding: Haliburton—Kawartha Lakes—Brock ===
CREATE ROLE riding_haliburtonkawarthalakesbrock_reader LOGIN PASSWORD 'udm+KKxH%JRm&F-d!-B@';
CREATE ROLE riding_haliburtonkawarthalakesbrock_writer LOGIN PASSWORD 'udm+KKxH%JRm&F-d!-B@' INHERIT;
GRANT riding_haliburtonkawarthalakesbrock_reader TO riding_haliburtonkawarthalakesbrock_writer;

CREATE POLICY riding_haliburtonkawarthalakesbrock_reader_read ON public.contact FOR SELECT TO riding_haliburtonkawarthalakesbrock_reader USING (division_electoral_district = 'Haliburton—Kawartha Lakes—Brock');
CREATE POLICY riding_haliburtonkawarthalakesbrock_writer_insert ON public.contact FOR INSERT TO riding_haliburtonkawarthalakesbrock_writer WITH CHECK (division_electoral_district = 'Haliburton—Kawartha Lakes—Brock');
CREATE POLICY riding_haliburtonkawarthalakesbrock_writer_update ON public.contact FOR UPDATE TO riding_haliburtonkawarthalakesbrock_writer USING (division_electoral_district = 'Haliburton—Kawartha Lakes—Brock') WITH CHECK (division_electoral_district = 'Haliburton—Kawartha Lakes—Brock');

GRANT SELECT ON public.contact TO riding_haliburtonkawarthalakesbrock_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_haliburtonkawarthalakesbrock_writer;

-- === Riding: Hamilton Centre ===
CREATE ROLE riding_hamiltoncentre_reader LOGIN PASSWORD 'RF=HBfxl_&971wnA2ir9';
CREATE ROLE riding_hamiltoncentre_writer LOGIN PASSWORD 'RF=HBfxl_&971wnA2ir9' INHERIT;
GRANT riding_hamiltoncentre_reader TO riding_hamiltoncentre_writer;

CREATE POLICY riding_hamiltoncentre_reader_read ON public.contact FOR SELECT TO riding_hamiltoncentre_reader USING (division_electoral_district = 'Hamilton Centre');
CREATE POLICY riding_hamiltoncentre_writer_insert ON public.contact FOR INSERT TO riding_hamiltoncentre_writer WITH CHECK (division_electoral_district = 'Hamilton Centre');
CREATE POLICY riding_hamiltoncentre_writer_update ON public.contact FOR UPDATE TO riding_hamiltoncentre_writer USING (division_electoral_district = 'Hamilton Centre') WITH CHECK (division_electoral_district = 'Hamilton Centre');

GRANT SELECT ON public.contact TO riding_hamiltoncentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_hamiltoncentre_writer;

-- === Riding: Hamilton East—Stoney Creek ===
CREATE ROLE riding_hamiltoneaststoneycreek_reader LOGIN PASSWORD 'EutgYW)H@bYStvI@-2qY';
CREATE ROLE riding_hamiltoneaststoneycreek_writer LOGIN PASSWORD 'EutgYW)H@bYStvI@-2qY' INHERIT;
GRANT riding_hamiltoneaststoneycreek_reader TO riding_hamiltoneaststoneycreek_writer;

CREATE POLICY riding_hamiltoneaststoneycreek_reader_read ON public.contact FOR SELECT TO riding_hamiltoneaststoneycreek_reader USING (division_electoral_district = 'Hamilton East—Stoney Creek');
CREATE POLICY riding_hamiltoneaststoneycreek_writer_insert ON public.contact FOR INSERT TO riding_hamiltoneaststoneycreek_writer WITH CHECK (division_electoral_district = 'Hamilton East—Stoney Creek');
CREATE POLICY riding_hamiltoneaststoneycreek_writer_update ON public.contact FOR UPDATE TO riding_hamiltoneaststoneycreek_writer USING (division_electoral_district = 'Hamilton East—Stoney Creek') WITH CHECK (division_electoral_district = 'Hamilton East—Stoney Creek');

GRANT SELECT ON public.contact TO riding_hamiltoneaststoneycreek_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_hamiltoneaststoneycreek_writer;

-- === Riding: Hamilton Mountain ===
CREATE ROLE riding_hamiltonmountain_reader LOGIN PASSWORD 'FcnNz)yd3nhgiwy4kkxT';
CREATE ROLE riding_hamiltonmountain_writer LOGIN PASSWORD 'FcnNz)yd3nhgiwy4kkxT' INHERIT;
GRANT riding_hamiltonmountain_reader TO riding_hamiltonmountain_writer;

CREATE POLICY riding_hamiltonmountain_reader_read ON public.contact FOR SELECT TO riding_hamiltonmountain_reader USING (division_electoral_district = 'Hamilton Mountain');
CREATE POLICY riding_hamiltonmountain_writer_insert ON public.contact FOR INSERT TO riding_hamiltonmountain_writer WITH CHECK (division_electoral_district = 'Hamilton Mountain');
CREATE POLICY riding_hamiltonmountain_writer_update ON public.contact FOR UPDATE TO riding_hamiltonmountain_writer USING (division_electoral_district = 'Hamilton Mountain') WITH CHECK (division_electoral_district = 'Hamilton Mountain');

GRANT SELECT ON public.contact TO riding_hamiltonmountain_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_hamiltonmountain_writer;

-- === Riding: Hamilton West—Ancaster—Dundas ===
CREATE ROLE riding_hamiltonwestancasterdundas_reader LOGIN PASSWORD 'V_xW7g*qom_vx!9+)ukY';
CREATE ROLE riding_hamiltonwestancasterdundas_writer LOGIN PASSWORD 'V_xW7g*qom_vx!9+)ukY' INHERIT;
GRANT riding_hamiltonwestancasterdundas_reader TO riding_hamiltonwestancasterdundas_writer;

CREATE POLICY riding_hamiltonwestancasterdundas_reader_read ON public.contact FOR SELECT TO riding_hamiltonwestancasterdundas_reader USING (division_electoral_district = 'Hamilton West—Ancaster—Dundas');
CREATE POLICY riding_hamiltonwestancasterdundas_writer_insert ON public.contact FOR INSERT TO riding_hamiltonwestancasterdundas_writer WITH CHECK (division_electoral_district = 'Hamilton West—Ancaster—Dundas');
CREATE POLICY riding_hamiltonwestancasterdundas_writer_update ON public.contact FOR UPDATE TO riding_hamiltonwestancasterdundas_writer USING (division_electoral_district = 'Hamilton West—Ancaster—Dundas') WITH CHECK (division_electoral_district = 'Hamilton West—Ancaster—Dundas');

GRANT SELECT ON public.contact TO riding_hamiltonwestancasterdundas_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_hamiltonwestancasterdundas_writer;

-- === Riding: Hastings—Lennox and Addington ===
CREATE ROLE riding_hastingslennoxandaddington_reader LOGIN PASSWORD 'jDu&=Ou7Y)BjB=mR^4h@';
CREATE ROLE riding_hastingslennoxandaddington_writer LOGIN PASSWORD 'jDu&=Ou7Y)BjB=mR^4h@' INHERIT;
GRANT riding_hastingslennoxandaddington_reader TO riding_hastingslennoxandaddington_writer;

CREATE POLICY riding_hastingslennoxandaddington_reader_read ON public.contact FOR SELECT TO riding_hastingslennoxandaddington_reader USING (division_electoral_district = 'Hastings—Lennox and Addington');
CREATE POLICY riding_hastingslennoxandaddington_writer_insert ON public.contact FOR INSERT TO riding_hastingslennoxandaddington_writer WITH CHECK (division_electoral_district = 'Hastings—Lennox and Addington');
CREATE POLICY riding_hastingslennoxandaddington_writer_update ON public.contact FOR UPDATE TO riding_hastingslennoxandaddington_writer USING (division_electoral_district = 'Hastings—Lennox and Addington') WITH CHECK (division_electoral_district = 'Hastings—Lennox and Addington');

GRANT SELECT ON public.contact TO riding_hastingslennoxandaddington_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_hastingslennoxandaddington_writer;

-- === Riding: Humber River—Black Creek ===
CREATE ROLE riding_humberriverblackcreek_reader LOGIN PASSWORD 'cFMP(cB(D@HbS78DxGX1';
CREATE ROLE riding_humberriverblackcreek_writer LOGIN PASSWORD 'cFMP(cB(D@HbS78DxGX1' INHERIT;
GRANT riding_humberriverblackcreek_reader TO riding_humberriverblackcreek_writer;

CREATE POLICY riding_humberriverblackcreek_reader_read ON public.contact FOR SELECT TO riding_humberriverblackcreek_reader USING (division_electoral_district = 'Humber River—Black Creek');
CREATE POLICY riding_humberriverblackcreek_writer_insert ON public.contact FOR INSERT TO riding_humberriverblackcreek_writer WITH CHECK (division_electoral_district = 'Humber River—Black Creek');
CREATE POLICY riding_humberriverblackcreek_writer_update ON public.contact FOR UPDATE TO riding_humberriverblackcreek_writer USING (division_electoral_district = 'Humber River—Black Creek') WITH CHECK (division_electoral_district = 'Humber River—Black Creek');

GRANT SELECT ON public.contact TO riding_humberriverblackcreek_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_humberriverblackcreek_writer;

-- === Riding: Huron—Bruce ===
CREATE ROLE riding_huronbruce_reader LOGIN PASSWORD '-V#Gx11+Wc9YTqy2j*d7';
CREATE ROLE riding_huronbruce_writer LOGIN PASSWORD '-V#Gx11+Wc9YTqy2j*d7' INHERIT;
GRANT riding_huronbruce_reader TO riding_huronbruce_writer;

CREATE POLICY riding_huronbruce_reader_read ON public.contact FOR SELECT TO riding_huronbruce_reader USING (division_electoral_district = 'Huron—Bruce');
CREATE POLICY riding_huronbruce_writer_insert ON public.contact FOR INSERT TO riding_huronbruce_writer WITH CHECK (division_electoral_district = 'Huron—Bruce');
CREATE POLICY riding_huronbruce_writer_update ON public.contact FOR UPDATE TO riding_huronbruce_writer USING (division_electoral_district = 'Huron—Bruce') WITH CHECK (division_electoral_district = 'Huron—Bruce');

GRANT SELECT ON public.contact TO riding_huronbruce_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_huronbruce_writer;

-- === Riding: Kanata—Carleton ===
CREATE ROLE riding_kanatacarleton_reader LOGIN PASSWORD '8i$JFHOhaVGCwf@k0AO%';
CREATE ROLE riding_kanatacarleton_writer LOGIN PASSWORD '8i$JFHOhaVGCwf@k0AO%' INHERIT;
GRANT riding_kanatacarleton_reader TO riding_kanatacarleton_writer;

CREATE POLICY riding_kanatacarleton_reader_read ON public.contact FOR SELECT TO riding_kanatacarleton_reader USING (division_electoral_district = 'Kanata—Carleton');
CREATE POLICY riding_kanatacarleton_writer_insert ON public.contact FOR INSERT TO riding_kanatacarleton_writer WITH CHECK (division_electoral_district = 'Kanata—Carleton');
CREATE POLICY riding_kanatacarleton_writer_update ON public.contact FOR UPDATE TO riding_kanatacarleton_writer USING (division_electoral_district = 'Kanata—Carleton') WITH CHECK (division_electoral_district = 'Kanata—Carleton');

GRANT SELECT ON public.contact TO riding_kanatacarleton_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kanatacarleton_writer;

-- === Riding: Kenora—Rainy River ===
CREATE ROLE riding_kenorarainyriver_reader LOGIN PASSWORD 'NBMFTPKD5Sz)K5!cyO6x';
CREATE ROLE riding_kenorarainyriver_writer LOGIN PASSWORD 'NBMFTPKD5Sz)K5!cyO6x' INHERIT;
GRANT riding_kenorarainyriver_reader TO riding_kenorarainyriver_writer;

CREATE POLICY riding_kenorarainyriver_reader_read ON public.contact FOR SELECT TO riding_kenorarainyriver_reader USING (division_electoral_district = 'Kenora—Rainy River');
CREATE POLICY riding_kenorarainyriver_writer_insert ON public.contact FOR INSERT TO riding_kenorarainyriver_writer WITH CHECK (division_electoral_district = 'Kenora—Rainy River');
CREATE POLICY riding_kenorarainyriver_writer_update ON public.contact FOR UPDATE TO riding_kenorarainyriver_writer USING (division_electoral_district = 'Kenora—Rainy River') WITH CHECK (division_electoral_district = 'Kenora—Rainy River');

GRANT SELECT ON public.contact TO riding_kenorarainyriver_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kenorarainyriver_writer;

-- === Riding: Kiiwetinoong ===
CREATE ROLE riding_kiiwetinoong_reader LOGIN PASSWORD 'Q8KNtnz9Q*nR5!6^lWen';
CREATE ROLE riding_kiiwetinoong_writer LOGIN PASSWORD 'Q8KNtnz9Q*nR5!6^lWen' INHERIT;
GRANT riding_kiiwetinoong_reader TO riding_kiiwetinoong_writer;

CREATE POLICY riding_kiiwetinoong_reader_read ON public.contact FOR SELECT TO riding_kiiwetinoong_reader USING (division_electoral_district = 'Kiiwetinoong');
CREATE POLICY riding_kiiwetinoong_writer_insert ON public.contact FOR INSERT TO riding_kiiwetinoong_writer WITH CHECK (division_electoral_district = 'Kiiwetinoong');
CREATE POLICY riding_kiiwetinoong_writer_update ON public.contact FOR UPDATE TO riding_kiiwetinoong_writer USING (division_electoral_district = 'Kiiwetinoong') WITH CHECK (division_electoral_district = 'Kiiwetinoong');

GRANT SELECT ON public.contact TO riding_kiiwetinoong_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kiiwetinoong_writer;

-- === Riding: Kingston and the Islands ===
CREATE ROLE riding_kingstonandtheislands_reader LOGIN PASSWORD 'qI9-ax3auUr#7PIrJ&yr';
CREATE ROLE riding_kingstonandtheislands_writer LOGIN PASSWORD 'qI9-ax3auUr#7PIrJ&yr' INHERIT;
GRANT riding_kingstonandtheislands_reader TO riding_kingstonandtheislands_writer;

CREATE POLICY riding_kingstonandtheislands_reader_read ON public.contact FOR SELECT TO riding_kingstonandtheislands_reader USING (division_electoral_district = 'Kingston and the Islands');
CREATE POLICY riding_kingstonandtheislands_writer_insert ON public.contact FOR INSERT TO riding_kingstonandtheislands_writer WITH CHECK (division_electoral_district = 'Kingston and the Islands');
CREATE POLICY riding_kingstonandtheislands_writer_update ON public.contact FOR UPDATE TO riding_kingstonandtheislands_writer USING (division_electoral_district = 'Kingston and the Islands') WITH CHECK (division_electoral_district = 'Kingston and the Islands');

GRANT SELECT ON public.contact TO riding_kingstonandtheislands_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kingstonandtheislands_writer;

-- === Riding: King—Vaughan ===
CREATE ROLE riding_kingvaughan_reader LOGIN PASSWORD 'NzEwn(dW(-r%cCS9J%qJ';
CREATE ROLE riding_kingvaughan_writer LOGIN PASSWORD 'NzEwn(dW(-r%cCS9J%qJ' INHERIT;
GRANT riding_kingvaughan_reader TO riding_kingvaughan_writer;

CREATE POLICY riding_kingvaughan_reader_read ON public.contact FOR SELECT TO riding_kingvaughan_reader USING (division_electoral_district = 'King—Vaughan');
CREATE POLICY riding_kingvaughan_writer_insert ON public.contact FOR INSERT TO riding_kingvaughan_writer WITH CHECK (division_electoral_district = 'King—Vaughan');
CREATE POLICY riding_kingvaughan_writer_update ON public.contact FOR UPDATE TO riding_kingvaughan_writer USING (division_electoral_district = 'King—Vaughan') WITH CHECK (division_electoral_district = 'King—Vaughan');

GRANT SELECT ON public.contact TO riding_kingvaughan_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kingvaughan_writer;

-- === Riding: Kitchener Centre ===
CREATE ROLE riding_kitchenercentre_reader LOGIN PASSWORD 'ZWxVRmejuka3fSd4l0FC';
CREATE ROLE riding_kitchenercentre_writer LOGIN PASSWORD 'ZWxVRmejuka3fSd4l0FC' INHERIT;
GRANT riding_kitchenercentre_reader TO riding_kitchenercentre_writer;

CREATE POLICY riding_kitchenercentre_reader_read ON public.contact FOR SELECT TO riding_kitchenercentre_reader USING (division_electoral_district = 'Kitchener Centre');
CREATE POLICY riding_kitchenercentre_writer_insert ON public.contact FOR INSERT TO riding_kitchenercentre_writer WITH CHECK (division_electoral_district = 'Kitchener Centre');
CREATE POLICY riding_kitchenercentre_writer_update ON public.contact FOR UPDATE TO riding_kitchenercentre_writer USING (division_electoral_district = 'Kitchener Centre') WITH CHECK (division_electoral_district = 'Kitchener Centre');

GRANT SELECT ON public.contact TO riding_kitchenercentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kitchenercentre_writer;

-- === Riding: Kitchener South—Hespeler ===
CREATE ROLE riding_kitchenersouthhespeler_reader LOGIN PASSWORD 'HfAB$-r@p=)gcpU%C0$p';
CREATE ROLE riding_kitchenersouthhespeler_writer LOGIN PASSWORD 'HfAB$-r@p=)gcpU%C0$p' INHERIT;
GRANT riding_kitchenersouthhespeler_reader TO riding_kitchenersouthhespeler_writer;

CREATE POLICY riding_kitchenersouthhespeler_reader_read ON public.contact FOR SELECT TO riding_kitchenersouthhespeler_reader USING (division_electoral_district = 'Kitchener South—Hespeler');
CREATE POLICY riding_kitchenersouthhespeler_writer_insert ON public.contact FOR INSERT TO riding_kitchenersouthhespeler_writer WITH CHECK (division_electoral_district = 'Kitchener South—Hespeler');
CREATE POLICY riding_kitchenersouthhespeler_writer_update ON public.contact FOR UPDATE TO riding_kitchenersouthhespeler_writer USING (division_electoral_district = 'Kitchener South—Hespeler') WITH CHECK (division_electoral_district = 'Kitchener South—Hespeler');

GRANT SELECT ON public.contact TO riding_kitchenersouthhespeler_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kitchenersouthhespeler_writer;

-- === Riding: Kitchener—Conestoga ===
CREATE ROLE riding_kitchenerconestoga_reader LOGIN PASSWORD 'w!BhV0a!b4+IiLxJ@gwW';
CREATE ROLE riding_kitchenerconestoga_writer LOGIN PASSWORD 'w!BhV0a!b4+IiLxJ@gwW' INHERIT;
GRANT riding_kitchenerconestoga_reader TO riding_kitchenerconestoga_writer;

CREATE POLICY riding_kitchenerconestoga_reader_read ON public.contact FOR SELECT TO riding_kitchenerconestoga_reader USING (division_electoral_district = 'Kitchener—Conestoga');
CREATE POLICY riding_kitchenerconestoga_writer_insert ON public.contact FOR INSERT TO riding_kitchenerconestoga_writer WITH CHECK (division_electoral_district = 'Kitchener—Conestoga');
CREATE POLICY riding_kitchenerconestoga_writer_update ON public.contact FOR UPDATE TO riding_kitchenerconestoga_writer USING (division_electoral_district = 'Kitchener—Conestoga') WITH CHECK (division_electoral_district = 'Kitchener—Conestoga');

GRANT SELECT ON public.contact TO riding_kitchenerconestoga_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_kitchenerconestoga_writer;

-- === Riding: Lambton—Kent—Middlesex ===
CREATE ROLE riding_lambtonkentmiddlesex_reader LOGIN PASSWORD 'b+q-Ak=g#x2R8E-98F&u';
CREATE ROLE riding_lambtonkentmiddlesex_writer LOGIN PASSWORD 'b+q-Ak=g#x2R8E-98F&u' INHERIT;
GRANT riding_lambtonkentmiddlesex_reader TO riding_lambtonkentmiddlesex_writer;

CREATE POLICY riding_lambtonkentmiddlesex_reader_read ON public.contact FOR SELECT TO riding_lambtonkentmiddlesex_reader USING (division_electoral_district = 'Lambton—Kent—Middlesex');
CREATE POLICY riding_lambtonkentmiddlesex_writer_insert ON public.contact FOR INSERT TO riding_lambtonkentmiddlesex_writer WITH CHECK (division_electoral_district = 'Lambton—Kent—Middlesex');
CREATE POLICY riding_lambtonkentmiddlesex_writer_update ON public.contact FOR UPDATE TO riding_lambtonkentmiddlesex_writer USING (division_electoral_district = 'Lambton—Kent—Middlesex') WITH CHECK (division_electoral_district = 'Lambton—Kent—Middlesex');

GRANT SELECT ON public.contact TO riding_lambtonkentmiddlesex_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_lambtonkentmiddlesex_writer;

-- === Riding: Lanark—Frontenac—Kingston ===
CREATE ROLE riding_lanarkfrontenackingston_reader LOGIN PASSWORD 'lQ_s1w4!RCvfDRYcfNIt';
CREATE ROLE riding_lanarkfrontenackingston_writer LOGIN PASSWORD 'lQ_s1w4!RCvfDRYcfNIt' INHERIT;
GRANT riding_lanarkfrontenackingston_reader TO riding_lanarkfrontenackingston_writer;

CREATE POLICY riding_lanarkfrontenackingston_reader_read ON public.contact FOR SELECT TO riding_lanarkfrontenackingston_reader USING (division_electoral_district = 'Lanark—Frontenac—Kingston');
CREATE POLICY riding_lanarkfrontenackingston_writer_insert ON public.contact FOR INSERT TO riding_lanarkfrontenackingston_writer WITH CHECK (division_electoral_district = 'Lanark—Frontenac—Kingston');
CREATE POLICY riding_lanarkfrontenackingston_writer_update ON public.contact FOR UPDATE TO riding_lanarkfrontenackingston_writer USING (division_electoral_district = 'Lanark—Frontenac—Kingston') WITH CHECK (division_electoral_district = 'Lanark—Frontenac—Kingston');

GRANT SELECT ON public.contact TO riding_lanarkfrontenackingston_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_lanarkfrontenackingston_writer;

-- === Riding: Leeds—Grenville—Thousand Islands and Rideau Lakes ===
CREATE ROLE riding_leedsgrenvillethousandislandsandrideaulakes_reader LOGIN PASSWORD 'qV#%r_o^DVcs#)1a*l86';
CREATE ROLE riding_leedsgrenvillethousandislandsandrideaulakes_writer LOGIN PASSWORD 'qV#%r_o^DVcs#)1a*l86' INHERIT;
GRANT riding_leedsgrenvillethousandislandsandrideaulakes_reader TO riding_leedsgrenvillethousandislandsandrideaulakes_writer;

CREATE POLICY riding_leedsgrenvillethousandislandsandrideaulakes_reader_read ON public.contact FOR SELECT TO riding_leedsgrenvillethousandislandsandrideaulakes_reader USING (division_electoral_district = 'Leeds—Grenville—Thousand Islands and Rideau Lakes');
CREATE POLICY riding_leedsgrenvillethousandislandsandrideaulakes_writer_insert ON public.contact FOR INSERT TO riding_leedsgrenvillethousandislandsandrideaulakes_writer WITH CHECK (division_electoral_district = 'Leeds—Grenville—Thousand Islands and Rideau Lakes');
CREATE POLICY riding_leedsgrenvillethousandislandsandrideaulakes_writer_update ON public.contact FOR UPDATE TO riding_leedsgrenvillethousandislandsandrideaulakes_writer USING (division_electoral_district = 'Leeds—Grenville—Thousand Islands and Rideau Lakes') WITH CHECK (division_electoral_district = 'Leeds—Grenville—Thousand Islands and Rideau Lakes');

GRANT SELECT ON public.contact TO riding_leedsgrenvillethousandislandsandrideaulakes_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_leedsgrenvillethousandislandsandrideaulakes_writer;

-- === Riding: London North Centre ===
CREATE ROLE riding_londonnorthcentre_reader LOGIN PASSWORD '(SY(4U()K0LEYFSJZoly';
CREATE ROLE riding_londonnorthcentre_writer LOGIN PASSWORD '(SY(4U()K0LEYFSJZoly' INHERIT;
GRANT riding_londonnorthcentre_reader TO riding_londonnorthcentre_writer;

CREATE POLICY riding_londonnorthcentre_reader_read ON public.contact FOR SELECT TO riding_londonnorthcentre_reader USING (division_electoral_district = 'London North Centre');
CREATE POLICY riding_londonnorthcentre_writer_insert ON public.contact FOR INSERT TO riding_londonnorthcentre_writer WITH CHECK (division_electoral_district = 'London North Centre');
CREATE POLICY riding_londonnorthcentre_writer_update ON public.contact FOR UPDATE TO riding_londonnorthcentre_writer USING (division_electoral_district = 'London North Centre') WITH CHECK (division_electoral_district = 'London North Centre');

GRANT SELECT ON public.contact TO riding_londonnorthcentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_londonnorthcentre_writer;

-- === Riding: London West ===
CREATE ROLE riding_londonwest_reader LOGIN PASSWORD 'jnc^m$sB!R2=i#I^&A-H';
CREATE ROLE riding_londonwest_writer LOGIN PASSWORD 'jnc^m$sB!R2=i#I^&A-H' INHERIT;
GRANT riding_londonwest_reader TO riding_londonwest_writer;

CREATE POLICY riding_londonwest_reader_read ON public.contact FOR SELECT TO riding_londonwest_reader USING (division_electoral_district = 'London West');
CREATE POLICY riding_londonwest_writer_insert ON public.contact FOR INSERT TO riding_londonwest_writer WITH CHECK (division_electoral_district = 'London West');
CREATE POLICY riding_londonwest_writer_update ON public.contact FOR UPDATE TO riding_londonwest_writer USING (division_electoral_district = 'London West') WITH CHECK (division_electoral_district = 'London West');

GRANT SELECT ON public.contact TO riding_londonwest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_londonwest_writer;

-- === Riding: London—Fanshawe ===
CREATE ROLE riding_londonfanshawe_reader LOGIN PASSWORD 'WYcif=RbscR$F7o*$H$Y';
CREATE ROLE riding_londonfanshawe_writer LOGIN PASSWORD 'WYcif=RbscR$F7o*$H$Y' INHERIT;
GRANT riding_londonfanshawe_reader TO riding_londonfanshawe_writer;

CREATE POLICY riding_londonfanshawe_reader_read ON public.contact FOR SELECT TO riding_londonfanshawe_reader USING (division_electoral_district = 'London—Fanshawe');
CREATE POLICY riding_londonfanshawe_writer_insert ON public.contact FOR INSERT TO riding_londonfanshawe_writer WITH CHECK (division_electoral_district = 'London—Fanshawe');
CREATE POLICY riding_londonfanshawe_writer_update ON public.contact FOR UPDATE TO riding_londonfanshawe_writer USING (division_electoral_district = 'London—Fanshawe') WITH CHECK (division_electoral_district = 'London—Fanshawe');

GRANT SELECT ON public.contact TO riding_londonfanshawe_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_londonfanshawe_writer;

-- === Riding: Markham—Stouffville ===
CREATE ROLE riding_markhamstouffville_reader LOGIN PASSWORD 'DR(3wpGmCnOD_X^y5w32';
CREATE ROLE riding_markhamstouffville_writer LOGIN PASSWORD 'DR(3wpGmCnOD_X^y5w32' INHERIT;
GRANT riding_markhamstouffville_reader TO riding_markhamstouffville_writer;

CREATE POLICY riding_markhamstouffville_reader_read ON public.contact FOR SELECT TO riding_markhamstouffville_reader USING (division_electoral_district = 'Markham—Stouffville');
CREATE POLICY riding_markhamstouffville_writer_insert ON public.contact FOR INSERT TO riding_markhamstouffville_writer WITH CHECK (division_electoral_district = 'Markham—Stouffville');
CREATE POLICY riding_markhamstouffville_writer_update ON public.contact FOR UPDATE TO riding_markhamstouffville_writer USING (division_electoral_district = 'Markham—Stouffville') WITH CHECK (division_electoral_district = 'Markham—Stouffville');

GRANT SELECT ON public.contact TO riding_markhamstouffville_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_markhamstouffville_writer;

-- === Riding: Markham—Thornhill ===
CREATE ROLE riding_markhamthornhill_reader LOGIN PASSWORD 'IO7hY-vPi01J@+MN1A9Z';
CREATE ROLE riding_markhamthornhill_writer LOGIN PASSWORD 'IO7hY-vPi01J@+MN1A9Z' INHERIT;
GRANT riding_markhamthornhill_reader TO riding_markhamthornhill_writer;

CREATE POLICY riding_markhamthornhill_reader_read ON public.contact FOR SELECT TO riding_markhamthornhill_reader USING (division_electoral_district = 'Markham—Thornhill');
CREATE POLICY riding_markhamthornhill_writer_insert ON public.contact FOR INSERT TO riding_markhamthornhill_writer WITH CHECK (division_electoral_district = 'Markham—Thornhill');
CREATE POLICY riding_markhamthornhill_writer_update ON public.contact FOR UPDATE TO riding_markhamthornhill_writer USING (division_electoral_district = 'Markham—Thornhill') WITH CHECK (division_electoral_district = 'Markham—Thornhill');

GRANT SELECT ON public.contact TO riding_markhamthornhill_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_markhamthornhill_writer;

-- === Riding: Markham—Unionville ===
CREATE ROLE riding_markhamunionville_reader LOGIN PASSWORD 'Q%)uzUkRswNN42oWY=U%';
CREATE ROLE riding_markhamunionville_writer LOGIN PASSWORD 'Q%)uzUkRswNN42oWY=U%' INHERIT;
GRANT riding_markhamunionville_reader TO riding_markhamunionville_writer;

CREATE POLICY riding_markhamunionville_reader_read ON public.contact FOR SELECT TO riding_markhamunionville_reader USING (division_electoral_district = 'Markham—Unionville');
CREATE POLICY riding_markhamunionville_writer_insert ON public.contact FOR INSERT TO riding_markhamunionville_writer WITH CHECK (division_electoral_district = 'Markham—Unionville');
CREATE POLICY riding_markhamunionville_writer_update ON public.contact FOR UPDATE TO riding_markhamunionville_writer USING (division_electoral_district = 'Markham—Unionville') WITH CHECK (division_electoral_district = 'Markham—Unionville');

GRANT SELECT ON public.contact TO riding_markhamunionville_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_markhamunionville_writer;

-- === Riding: Milton ===
CREATE ROLE riding_milton_reader LOGIN PASSWORD 'Ur#W3MsHqg!(yQ1tOI@L';
CREATE ROLE riding_milton_writer LOGIN PASSWORD 'Ur#W3MsHqg!(yQ1tOI@L' INHERIT;
GRANT riding_milton_reader TO riding_milton_writer;

CREATE POLICY riding_milton_reader_read ON public.contact FOR SELECT TO riding_milton_reader USING (division_electoral_district = 'Milton');
CREATE POLICY riding_milton_writer_insert ON public.contact FOR INSERT TO riding_milton_writer WITH CHECK (division_electoral_district = 'Milton');
CREATE POLICY riding_milton_writer_update ON public.contact FOR UPDATE TO riding_milton_writer USING (division_electoral_district = 'Milton') WITH CHECK (division_electoral_district = 'Milton');

GRANT SELECT ON public.contact TO riding_milton_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_milton_writer;

-- === Riding: Mississauga Centre ===
CREATE ROLE riding_mississaugacentre_reader LOGIN PASSWORD 'L7gsK&sM1AUW6q$xK@DG';
CREATE ROLE riding_mississaugacentre_writer LOGIN PASSWORD 'L7gsK&sM1AUW6q$xK@DG' INHERIT;
GRANT riding_mississaugacentre_reader TO riding_mississaugacentre_writer;

CREATE POLICY riding_mississaugacentre_reader_read ON public.contact FOR SELECT TO riding_mississaugacentre_reader USING (division_electoral_district = 'Mississauga Centre');
CREATE POLICY riding_mississaugacentre_writer_insert ON public.contact FOR INSERT TO riding_mississaugacentre_writer WITH CHECK (division_electoral_district = 'Mississauga Centre');
CREATE POLICY riding_mississaugacentre_writer_update ON public.contact FOR UPDATE TO riding_mississaugacentre_writer USING (division_electoral_district = 'Mississauga Centre') WITH CHECK (division_electoral_district = 'Mississauga Centre');

GRANT SELECT ON public.contact TO riding_mississaugacentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_mississaugacentre_writer;

-- === Riding: Mississauga East—Cooksville ===
CREATE ROLE riding_mississaugaeastcooksville_reader LOGIN PASSWORD 'f=6q$LeWQ4va-YPNU1Ju';
CREATE ROLE riding_mississaugaeastcooksville_writer LOGIN PASSWORD 'f=6q$LeWQ4va-YPNU1Ju' INHERIT;
GRANT riding_mississaugaeastcooksville_reader TO riding_mississaugaeastcooksville_writer;

CREATE POLICY riding_mississaugaeastcooksville_reader_read ON public.contact FOR SELECT TO riding_mississaugaeastcooksville_reader USING (division_electoral_district = 'Mississauga East—Cooksville');
CREATE POLICY riding_mississaugaeastcooksville_writer_insert ON public.contact FOR INSERT TO riding_mississaugaeastcooksville_writer WITH CHECK (division_electoral_district = 'Mississauga East—Cooksville');
CREATE POLICY riding_mississaugaeastcooksville_writer_update ON public.contact FOR UPDATE TO riding_mississaugaeastcooksville_writer USING (division_electoral_district = 'Mississauga East—Cooksville') WITH CHECK (division_electoral_district = 'Mississauga East—Cooksville');

GRANT SELECT ON public.contact TO riding_mississaugaeastcooksville_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_mississaugaeastcooksville_writer;

-- === Riding: Mississauga—Erin Mills ===
CREATE ROLE riding_mississaugaerinmills_reader LOGIN PASSWORD 'p$tm)lpf&Q0oVdceasmB';
CREATE ROLE riding_mississaugaerinmills_writer LOGIN PASSWORD 'p$tm)lpf&Q0oVdceasmB' INHERIT;
GRANT riding_mississaugaerinmills_reader TO riding_mississaugaerinmills_writer;

CREATE POLICY riding_mississaugaerinmills_reader_read ON public.contact FOR SELECT TO riding_mississaugaerinmills_reader USING (division_electoral_district = 'Mississauga—Erin Mills');
CREATE POLICY riding_mississaugaerinmills_writer_insert ON public.contact FOR INSERT TO riding_mississaugaerinmills_writer WITH CHECK (division_electoral_district = 'Mississauga—Erin Mills');
CREATE POLICY riding_mississaugaerinmills_writer_update ON public.contact FOR UPDATE TO riding_mississaugaerinmills_writer USING (division_electoral_district = 'Mississauga—Erin Mills') WITH CHECK (division_electoral_district = 'Mississauga—Erin Mills');

GRANT SELECT ON public.contact TO riding_mississaugaerinmills_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_mississaugaerinmills_writer;

-- === Riding: Mississauga—Lakeshore ===
CREATE ROLE riding_mississaugalakeshore_reader LOGIN PASSWORD 'UpYR7!aq7SM!spbzNhl$';
CREATE ROLE riding_mississaugalakeshore_writer LOGIN PASSWORD 'UpYR7!aq7SM!spbzNhl$' INHERIT;
GRANT riding_mississaugalakeshore_reader TO riding_mississaugalakeshore_writer;

CREATE POLICY riding_mississaugalakeshore_reader_read ON public.contact FOR SELECT TO riding_mississaugalakeshore_reader USING (division_electoral_district = 'Mississauga—Lakeshore');
CREATE POLICY riding_mississaugalakeshore_writer_insert ON public.contact FOR INSERT TO riding_mississaugalakeshore_writer WITH CHECK (division_electoral_district = 'Mississauga—Lakeshore');
CREATE POLICY riding_mississaugalakeshore_writer_update ON public.contact FOR UPDATE TO riding_mississaugalakeshore_writer USING (division_electoral_district = 'Mississauga—Lakeshore') WITH CHECK (division_electoral_district = 'Mississauga—Lakeshore');

GRANT SELECT ON public.contact TO riding_mississaugalakeshore_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_mississaugalakeshore_writer;

-- === Riding: Mississauga—Malton ===
CREATE ROLE riding_mississaugamalton_reader LOGIN PASSWORD 'k0Y7e8RLoy(vT5vXK(DA';
CREATE ROLE riding_mississaugamalton_writer LOGIN PASSWORD 'k0Y7e8RLoy(vT5vXK(DA' INHERIT;
GRANT riding_mississaugamalton_reader TO riding_mississaugamalton_writer;

CREATE POLICY riding_mississaugamalton_reader_read ON public.contact FOR SELECT TO riding_mississaugamalton_reader USING (division_electoral_district = 'Mississauga—Malton');
CREATE POLICY riding_mississaugamalton_writer_insert ON public.contact FOR INSERT TO riding_mississaugamalton_writer WITH CHECK (division_electoral_district = 'Mississauga—Malton');
CREATE POLICY riding_mississaugamalton_writer_update ON public.contact FOR UPDATE TO riding_mississaugamalton_writer USING (division_electoral_district = 'Mississauga—Malton') WITH CHECK (division_electoral_district = 'Mississauga—Malton');

GRANT SELECT ON public.contact TO riding_mississaugamalton_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_mississaugamalton_writer;

-- === Riding: Mississauga—Streetsville ===
CREATE ROLE riding_mississaugastreetsville_reader LOGIN PASSWORD 'JNI9rxEznO=_2L4il8Hu';
CREATE ROLE riding_mississaugastreetsville_writer LOGIN PASSWORD 'JNI9rxEznO=_2L4il8Hu' INHERIT;
GRANT riding_mississaugastreetsville_reader TO riding_mississaugastreetsville_writer;

CREATE POLICY riding_mississaugastreetsville_reader_read ON public.contact FOR SELECT TO riding_mississaugastreetsville_reader USING (division_electoral_district = 'Mississauga—Streetsville');
CREATE POLICY riding_mississaugastreetsville_writer_insert ON public.contact FOR INSERT TO riding_mississaugastreetsville_writer WITH CHECK (division_electoral_district = 'Mississauga—Streetsville');
CREATE POLICY riding_mississaugastreetsville_writer_update ON public.contact FOR UPDATE TO riding_mississaugastreetsville_writer USING (division_electoral_district = 'Mississauga—Streetsville') WITH CHECK (division_electoral_district = 'Mississauga—Streetsville');

GRANT SELECT ON public.contact TO riding_mississaugastreetsville_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_mississaugastreetsville_writer;

-- === Riding: Mushkegowuk—James Bay ===
CREATE ROLE riding_mushkegowukjamesbay_reader LOGIN PASSWORD 'jZbzy7_usg9-fwX6JQwB';
CREATE ROLE riding_mushkegowukjamesbay_writer LOGIN PASSWORD 'jZbzy7_usg9-fwX6JQwB' INHERIT;
GRANT riding_mushkegowukjamesbay_reader TO riding_mushkegowukjamesbay_writer;

CREATE POLICY riding_mushkegowukjamesbay_reader_read ON public.contact FOR SELECT TO riding_mushkegowukjamesbay_reader USING (division_electoral_district = 'Mushkegowuk—James Bay');
CREATE POLICY riding_mushkegowukjamesbay_writer_insert ON public.contact FOR INSERT TO riding_mushkegowukjamesbay_writer WITH CHECK (division_electoral_district = 'Mushkegowuk—James Bay');
CREATE POLICY riding_mushkegowukjamesbay_writer_update ON public.contact FOR UPDATE TO riding_mushkegowukjamesbay_writer USING (division_electoral_district = 'Mushkegowuk—James Bay') WITH CHECK (division_electoral_district = 'Mushkegowuk—James Bay');

GRANT SELECT ON public.contact TO riding_mushkegowukjamesbay_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_mushkegowukjamesbay_writer;

-- === Riding: Nepean ===
CREATE ROLE riding_nepean_reader LOGIN PASSWORD 'Aza)V3HxCts1IoUU$UiZ';
CREATE ROLE riding_nepean_writer LOGIN PASSWORD 'Aza)V3HxCts1IoUU$UiZ' INHERIT;
GRANT riding_nepean_reader TO riding_nepean_writer;

CREATE POLICY riding_nepean_reader_read ON public.contact FOR SELECT TO riding_nepean_reader USING (division_electoral_district = 'Nepean');
CREATE POLICY riding_nepean_writer_insert ON public.contact FOR INSERT TO riding_nepean_writer WITH CHECK (division_electoral_district = 'Nepean');
CREATE POLICY riding_nepean_writer_update ON public.contact FOR UPDATE TO riding_nepean_writer USING (division_electoral_district = 'Nepean') WITH CHECK (division_electoral_district = 'Nepean');

GRANT SELECT ON public.contact TO riding_nepean_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_nepean_writer;

-- === Riding: Newmarket—Aurora ===
CREATE ROLE riding_newmarketaurora_reader LOGIN PASSWORD 'C8UbPFdZ)iIBI842hSf4';
CREATE ROLE riding_newmarketaurora_writer LOGIN PASSWORD 'C8UbPFdZ)iIBI842hSf4' INHERIT;
GRANT riding_newmarketaurora_reader TO riding_newmarketaurora_writer;

CREATE POLICY riding_newmarketaurora_reader_read ON public.contact FOR SELECT TO riding_newmarketaurora_reader USING (division_electoral_district = 'Newmarket—Aurora');
CREATE POLICY riding_newmarketaurora_writer_insert ON public.contact FOR INSERT TO riding_newmarketaurora_writer WITH CHECK (division_electoral_district = 'Newmarket—Aurora');
CREATE POLICY riding_newmarketaurora_writer_update ON public.contact FOR UPDATE TO riding_newmarketaurora_writer USING (division_electoral_district = 'Newmarket—Aurora') WITH CHECK (division_electoral_district = 'Newmarket—Aurora');

GRANT SELECT ON public.contact TO riding_newmarketaurora_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_newmarketaurora_writer;

-- === Riding: Niagara Centre ===
CREATE ROLE riding_niagaracentre_reader LOGIN PASSWORD 'o@%HTb6kaqvOW)3DMfY7';
CREATE ROLE riding_niagaracentre_writer LOGIN PASSWORD 'o@%HTb6kaqvOW)3DMfY7' INHERIT;
GRANT riding_niagaracentre_reader TO riding_niagaracentre_writer;

CREATE POLICY riding_niagaracentre_reader_read ON public.contact FOR SELECT TO riding_niagaracentre_reader USING (division_electoral_district = 'Niagara Centre');
CREATE POLICY riding_niagaracentre_writer_insert ON public.contact FOR INSERT TO riding_niagaracentre_writer WITH CHECK (division_electoral_district = 'Niagara Centre');
CREATE POLICY riding_niagaracentre_writer_update ON public.contact FOR UPDATE TO riding_niagaracentre_writer USING (division_electoral_district = 'Niagara Centre') WITH CHECK (division_electoral_district = 'Niagara Centre');

GRANT SELECT ON public.contact TO riding_niagaracentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_niagaracentre_writer;

-- === Riding: Niagara Falls ===
CREATE ROLE riding_niagarafalls_reader LOGIN PASSWORD 'GewCl^=R08+CUC7jJPVl';
CREATE ROLE riding_niagarafalls_writer LOGIN PASSWORD 'GewCl^=R08+CUC7jJPVl' INHERIT;
GRANT riding_niagarafalls_reader TO riding_niagarafalls_writer;

CREATE POLICY riding_niagarafalls_reader_read ON public.contact FOR SELECT TO riding_niagarafalls_reader USING (division_electoral_district = 'Niagara Falls');
CREATE POLICY riding_niagarafalls_writer_insert ON public.contact FOR INSERT TO riding_niagarafalls_writer WITH CHECK (division_electoral_district = 'Niagara Falls');
CREATE POLICY riding_niagarafalls_writer_update ON public.contact FOR UPDATE TO riding_niagarafalls_writer USING (division_electoral_district = 'Niagara Falls') WITH CHECK (division_electoral_district = 'Niagara Falls');

GRANT SELECT ON public.contact TO riding_niagarafalls_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_niagarafalls_writer;

-- === Riding: Niagara West ===
CREATE ROLE riding_niagarawest_reader LOGIN PASSWORD 'sP31hUULseJd%Qw8#1jW';
CREATE ROLE riding_niagarawest_writer LOGIN PASSWORD 'sP31hUULseJd%Qw8#1jW' INHERIT;
GRANT riding_niagarawest_reader TO riding_niagarawest_writer;

CREATE POLICY riding_niagarawest_reader_read ON public.contact FOR SELECT TO riding_niagarawest_reader USING (division_electoral_district = 'Niagara West');
CREATE POLICY riding_niagarawest_writer_insert ON public.contact FOR INSERT TO riding_niagarawest_writer WITH CHECK (division_electoral_district = 'Niagara West');
CREATE POLICY riding_niagarawest_writer_update ON public.contact FOR UPDATE TO riding_niagarawest_writer USING (division_electoral_district = 'Niagara West') WITH CHECK (division_electoral_district = 'Niagara West');

GRANT SELECT ON public.contact TO riding_niagarawest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_niagarawest_writer;

-- === Riding: Nickel Belt ===
CREATE ROLE riding_nickelbelt_reader LOGIN PASSWORD '7+1V5tTVy9G!Rd7Jm*NB';
CREATE ROLE riding_nickelbelt_writer LOGIN PASSWORD '7+1V5tTVy9G!Rd7Jm*NB' INHERIT;
GRANT riding_nickelbelt_reader TO riding_nickelbelt_writer;

CREATE POLICY riding_nickelbelt_reader_read ON public.contact FOR SELECT TO riding_nickelbelt_reader USING (division_electoral_district = 'Nickel Belt');
CREATE POLICY riding_nickelbelt_writer_insert ON public.contact FOR INSERT TO riding_nickelbelt_writer WITH CHECK (division_electoral_district = 'Nickel Belt');
CREATE POLICY riding_nickelbelt_writer_update ON public.contact FOR UPDATE TO riding_nickelbelt_writer USING (division_electoral_district = 'Nickel Belt') WITH CHECK (division_electoral_district = 'Nickel Belt');

GRANT SELECT ON public.contact TO riding_nickelbelt_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_nickelbelt_writer;

-- === Riding: Nipissing ===
CREATE ROLE riding_nipissing_reader LOGIN PASSWORD 'xmjxK$u8+mNY3EIRJwIS';
CREATE ROLE riding_nipissing_writer LOGIN PASSWORD 'xmjxK$u8+mNY3EIRJwIS' INHERIT;
GRANT riding_nipissing_reader TO riding_nipissing_writer;

CREATE POLICY riding_nipissing_reader_read ON public.contact FOR SELECT TO riding_nipissing_reader USING (division_electoral_district = 'Nipissing');
CREATE POLICY riding_nipissing_writer_insert ON public.contact FOR INSERT TO riding_nipissing_writer WITH CHECK (division_electoral_district = 'Nipissing');
CREATE POLICY riding_nipissing_writer_update ON public.contact FOR UPDATE TO riding_nipissing_writer USING (division_electoral_district = 'Nipissing') WITH CHECK (division_electoral_district = 'Nipissing');

GRANT SELECT ON public.contact TO riding_nipissing_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_nipissing_writer;

-- === Riding: Northumberland—Peterborough South ===
CREATE ROLE riding_northumberlandpeterboroughsouth_reader LOGIN PASSWORD 'lM4kX3UQ)tZ3vAHC!Yww';
CREATE ROLE riding_northumberlandpeterboroughsouth_writer LOGIN PASSWORD 'lM4kX3UQ)tZ3vAHC!Yww' INHERIT;
GRANT riding_northumberlandpeterboroughsouth_reader TO riding_northumberlandpeterboroughsouth_writer;

CREATE POLICY riding_northumberlandpeterboroughsouth_reader_read ON public.contact FOR SELECT TO riding_northumberlandpeterboroughsouth_reader USING (division_electoral_district = 'Northumberland—Peterborough South');
CREATE POLICY riding_northumberlandpeterboroughsouth_writer_insert ON public.contact FOR INSERT TO riding_northumberlandpeterboroughsouth_writer WITH CHECK (division_electoral_district = 'Northumberland—Peterborough South');
CREATE POLICY riding_northumberlandpeterboroughsouth_writer_update ON public.contact FOR UPDATE TO riding_northumberlandpeterboroughsouth_writer USING (division_electoral_district = 'Northumberland—Peterborough South') WITH CHECK (division_electoral_district = 'Northumberland—Peterborough South');

GRANT SELECT ON public.contact TO riding_northumberlandpeterboroughsouth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_northumberlandpeterboroughsouth_writer;

-- === Riding: Oakville ===
CREATE ROLE riding_oakville_reader LOGIN PASSWORD 'C5+kO5NHMJan!=huSMu*';
CREATE ROLE riding_oakville_writer LOGIN PASSWORD 'C5+kO5NHMJan!=huSMu*' INHERIT;
GRANT riding_oakville_reader TO riding_oakville_writer;

CREATE POLICY riding_oakville_reader_read ON public.contact FOR SELECT TO riding_oakville_reader USING (division_electoral_district = 'Oakville');
CREATE POLICY riding_oakville_writer_insert ON public.contact FOR INSERT TO riding_oakville_writer WITH CHECK (division_electoral_district = 'Oakville');
CREATE POLICY riding_oakville_writer_update ON public.contact FOR UPDATE TO riding_oakville_writer USING (division_electoral_district = 'Oakville') WITH CHECK (division_electoral_district = 'Oakville');

GRANT SELECT ON public.contact TO riding_oakville_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_oakville_writer;

-- === Riding: Oakville North—Burlington ===
CREATE ROLE riding_oakvillenorthburlington_reader LOGIN PASSWORD 'MxV=1k$9vJ05o%1T=6-v';
CREATE ROLE riding_oakvillenorthburlington_writer LOGIN PASSWORD 'MxV=1k$9vJ05o%1T=6-v' INHERIT;
GRANT riding_oakvillenorthburlington_reader TO riding_oakvillenorthburlington_writer;

CREATE POLICY riding_oakvillenorthburlington_reader_read ON public.contact FOR SELECT TO riding_oakvillenorthburlington_reader USING (division_electoral_district = 'Oakville North—Burlington');
CREATE POLICY riding_oakvillenorthburlington_writer_insert ON public.contact FOR INSERT TO riding_oakvillenorthburlington_writer WITH CHECK (division_electoral_district = 'Oakville North—Burlington');
CREATE POLICY riding_oakvillenorthburlington_writer_update ON public.contact FOR UPDATE TO riding_oakvillenorthburlington_writer USING (division_electoral_district = 'Oakville North—Burlington') WITH CHECK (division_electoral_district = 'Oakville North—Burlington');

GRANT SELECT ON public.contact TO riding_oakvillenorthburlington_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_oakvillenorthburlington_writer;

-- === Riding: Orléans ===
CREATE ROLE riding_orlans_reader LOGIN PASSWORD '8GuT+OP7j4v$GVf5bm8l';
CREATE ROLE riding_orlans_writer LOGIN PASSWORD '8GuT+OP7j4v$GVf5bm8l' INHERIT;
GRANT riding_orlans_reader TO riding_orlans_writer;

CREATE POLICY riding_orlans_reader_read ON public.contact FOR SELECT TO riding_orlans_reader USING (division_electoral_district = 'Orléans');
CREATE POLICY riding_orlans_writer_insert ON public.contact FOR INSERT TO riding_orlans_writer WITH CHECK (division_electoral_district = 'Orléans');
CREATE POLICY riding_orlans_writer_update ON public.contact FOR UPDATE TO riding_orlans_writer USING (division_electoral_district = 'Orléans') WITH CHECK (division_electoral_district = 'Orléans');

GRANT SELECT ON public.contact TO riding_orlans_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_orlans_writer;

-- === Riding: Oshawa ===
CREATE ROLE riding_oshawa_reader LOGIN PASSWORD '=QsqA2YWQgRR01kFhwoo';
CREATE ROLE riding_oshawa_writer LOGIN PASSWORD '=QsqA2YWQgRR01kFhwoo' INHERIT;
GRANT riding_oshawa_reader TO riding_oshawa_writer;

CREATE POLICY riding_oshawa_reader_read ON public.contact FOR SELECT TO riding_oshawa_reader USING (division_electoral_district = 'Oshawa');
CREATE POLICY riding_oshawa_writer_insert ON public.contact FOR INSERT TO riding_oshawa_writer WITH CHECK (division_electoral_district = 'Oshawa');
CREATE POLICY riding_oshawa_writer_update ON public.contact FOR UPDATE TO riding_oshawa_writer USING (division_electoral_district = 'Oshawa') WITH CHECK (division_electoral_district = 'Oshawa');

GRANT SELECT ON public.contact TO riding_oshawa_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_oshawa_writer;

-- === Riding: Ottawa Centre ===
CREATE ROLE riding_ottawacentre_reader LOGIN PASSWORD '#fwx3GzDDkcctZQ72OTJ';
CREATE ROLE riding_ottawacentre_writer LOGIN PASSWORD '#fwx3GzDDkcctZQ72OTJ' INHERIT;
GRANT riding_ottawacentre_reader TO riding_ottawacentre_writer;

CREATE POLICY riding_ottawacentre_reader_read ON public.contact FOR SELECT TO riding_ottawacentre_reader USING (division_electoral_district = 'Ottawa Centre');
CREATE POLICY riding_ottawacentre_writer_insert ON public.contact FOR INSERT TO riding_ottawacentre_writer WITH CHECK (division_electoral_district = 'Ottawa Centre');
CREATE POLICY riding_ottawacentre_writer_update ON public.contact FOR UPDATE TO riding_ottawacentre_writer USING (division_electoral_district = 'Ottawa Centre') WITH CHECK (division_electoral_district = 'Ottawa Centre');

GRANT SELECT ON public.contact TO riding_ottawacentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_ottawacentre_writer;

-- === Riding: Ottawa South ===
CREATE ROLE riding_ottawasouth_reader LOGIN PASSWORD 'YoWL!acmeRfvTohr$XxR';
CREATE ROLE riding_ottawasouth_writer LOGIN PASSWORD 'YoWL!acmeRfvTohr$XxR' INHERIT;
GRANT riding_ottawasouth_reader TO riding_ottawasouth_writer;

CREATE POLICY riding_ottawasouth_reader_read ON public.contact FOR SELECT TO riding_ottawasouth_reader USING (division_electoral_district = 'Ottawa South');
CREATE POLICY riding_ottawasouth_writer_insert ON public.contact FOR INSERT TO riding_ottawasouth_writer WITH CHECK (division_electoral_district = 'Ottawa South');
CREATE POLICY riding_ottawasouth_writer_update ON public.contact FOR UPDATE TO riding_ottawasouth_writer USING (division_electoral_district = 'Ottawa South') WITH CHECK (division_electoral_district = 'Ottawa South');

GRANT SELECT ON public.contact TO riding_ottawasouth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_ottawasouth_writer;

-- === Riding: Ottawa West—Nepean ===
CREATE ROLE riding_ottawawestnepean_reader LOGIN PASSWORD 'pruD5s-RmXYSSTucdpdB';
CREATE ROLE riding_ottawawestnepean_writer LOGIN PASSWORD 'pruD5s-RmXYSSTucdpdB' INHERIT;
GRANT riding_ottawawestnepean_reader TO riding_ottawawestnepean_writer;

CREATE POLICY riding_ottawawestnepean_reader_read ON public.contact FOR SELECT TO riding_ottawawestnepean_reader USING (division_electoral_district = 'Ottawa West—Nepean');
CREATE POLICY riding_ottawawestnepean_writer_insert ON public.contact FOR INSERT TO riding_ottawawestnepean_writer WITH CHECK (division_electoral_district = 'Ottawa West—Nepean');
CREATE POLICY riding_ottawawestnepean_writer_update ON public.contact FOR UPDATE TO riding_ottawawestnepean_writer USING (division_electoral_district = 'Ottawa West—Nepean') WITH CHECK (division_electoral_district = 'Ottawa West—Nepean');

GRANT SELECT ON public.contact TO riding_ottawawestnepean_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_ottawawestnepean_writer;

-- === Riding: Ottawa—Vanier ===
CREATE ROLE riding_ottawavanier_reader LOGIN PASSWORD 'dxRhr9C5XC!-3ux@!idQ';
CREATE ROLE riding_ottawavanier_writer LOGIN PASSWORD 'dxRhr9C5XC!-3ux@!idQ' INHERIT;
GRANT riding_ottawavanier_reader TO riding_ottawavanier_writer;

CREATE POLICY riding_ottawavanier_reader_read ON public.contact FOR SELECT TO riding_ottawavanier_reader USING (division_electoral_district = 'Ottawa—Vanier');
CREATE POLICY riding_ottawavanier_writer_insert ON public.contact FOR INSERT TO riding_ottawavanier_writer WITH CHECK (division_electoral_district = 'Ottawa—Vanier');
CREATE POLICY riding_ottawavanier_writer_update ON public.contact FOR UPDATE TO riding_ottawavanier_writer USING (division_electoral_district = 'Ottawa—Vanier') WITH CHECK (division_electoral_district = 'Ottawa—Vanier');

GRANT SELECT ON public.contact TO riding_ottawavanier_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_ottawavanier_writer;

-- === Riding: Oxford ===
CREATE ROLE riding_oxford_reader LOGIN PASSWORD 'ueKZe!=N9N*v*j7hG_2o';
CREATE ROLE riding_oxford_writer LOGIN PASSWORD 'ueKZe!=N9N*v*j7hG_2o' INHERIT;
GRANT riding_oxford_reader TO riding_oxford_writer;

CREATE POLICY riding_oxford_reader_read ON public.contact FOR SELECT TO riding_oxford_reader USING (division_electoral_district = 'Oxford');
CREATE POLICY riding_oxford_writer_insert ON public.contact FOR INSERT TO riding_oxford_writer WITH CHECK (division_electoral_district = 'Oxford');
CREATE POLICY riding_oxford_writer_update ON public.contact FOR UPDATE TO riding_oxford_writer USING (division_electoral_district = 'Oxford') WITH CHECK (division_electoral_district = 'Oxford');

GRANT SELECT ON public.contact TO riding_oxford_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_oxford_writer;

-- === Riding: Parkdale—High Park ===
CREATE ROLE riding_parkdalehighpark_reader LOGIN PASSWORD 'm)fM5VCD=apffPA#FqT5';
CREATE ROLE riding_parkdalehighpark_writer LOGIN PASSWORD 'm)fM5VCD=apffPA#FqT5' INHERIT;
GRANT riding_parkdalehighpark_reader TO riding_parkdalehighpark_writer;

CREATE POLICY riding_parkdalehighpark_reader_read ON public.contact FOR SELECT TO riding_parkdalehighpark_reader USING (division_electoral_district = 'Parkdale—High Park');
CREATE POLICY riding_parkdalehighpark_writer_insert ON public.contact FOR INSERT TO riding_parkdalehighpark_writer WITH CHECK (division_electoral_district = 'Parkdale—High Park');
CREATE POLICY riding_parkdalehighpark_writer_update ON public.contact FOR UPDATE TO riding_parkdalehighpark_writer USING (division_electoral_district = 'Parkdale—High Park') WITH CHECK (division_electoral_district = 'Parkdale—High Park');

GRANT SELECT ON public.contact TO riding_parkdalehighpark_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_parkdalehighpark_writer;

-- === Riding: Parry Sound—Muskoka ===
CREATE ROLE riding_parrysoundmuskoka_reader LOGIN PASSWORD 'jllkVqGpXnA+#o9RExHs';
CREATE ROLE riding_parrysoundmuskoka_writer LOGIN PASSWORD 'jllkVqGpXnA+#o9RExHs' INHERIT;
GRANT riding_parrysoundmuskoka_reader TO riding_parrysoundmuskoka_writer;

CREATE POLICY riding_parrysoundmuskoka_reader_read ON public.contact FOR SELECT TO riding_parrysoundmuskoka_reader USING (division_electoral_district = 'Parry Sound—Muskoka');
CREATE POLICY riding_parrysoundmuskoka_writer_insert ON public.contact FOR INSERT TO riding_parrysoundmuskoka_writer WITH CHECK (division_electoral_district = 'Parry Sound—Muskoka');
CREATE POLICY riding_parrysoundmuskoka_writer_update ON public.contact FOR UPDATE TO riding_parrysoundmuskoka_writer USING (division_electoral_district = 'Parry Sound—Muskoka') WITH CHECK (division_electoral_district = 'Parry Sound—Muskoka');

GRANT SELECT ON public.contact TO riding_parrysoundmuskoka_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_parrysoundmuskoka_writer;

-- === Riding: Perth—Wellington ===
CREATE ROLE riding_perthwellington_reader LOGIN PASSWORD 'B@12D2q^CS!AIit)rpAV';
CREATE ROLE riding_perthwellington_writer LOGIN PASSWORD 'B@12D2q^CS!AIit)rpAV' INHERIT;
GRANT riding_perthwellington_reader TO riding_perthwellington_writer;

CREATE POLICY riding_perthwellington_reader_read ON public.contact FOR SELECT TO riding_perthwellington_reader USING (division_electoral_district = 'Perth—Wellington');
CREATE POLICY riding_perthwellington_writer_insert ON public.contact FOR INSERT TO riding_perthwellington_writer WITH CHECK (division_electoral_district = 'Perth—Wellington');
CREATE POLICY riding_perthwellington_writer_update ON public.contact FOR UPDATE TO riding_perthwellington_writer USING (division_electoral_district = 'Perth—Wellington') WITH CHECK (division_electoral_district = 'Perth—Wellington');

GRANT SELECT ON public.contact TO riding_perthwellington_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_perthwellington_writer;

-- === Riding: Peterborough—Kawartha ===
CREATE ROLE riding_peterboroughkawartha_reader LOGIN PASSWORD 'i0runLYt1Wp+E1Q75vW0';
CREATE ROLE riding_peterboroughkawartha_writer LOGIN PASSWORD 'i0runLYt1Wp+E1Q75vW0' INHERIT;
GRANT riding_peterboroughkawartha_reader TO riding_peterboroughkawartha_writer;

CREATE POLICY riding_peterboroughkawartha_reader_read ON public.contact FOR SELECT TO riding_peterboroughkawartha_reader USING (division_electoral_district = 'Peterborough—Kawartha');
CREATE POLICY riding_peterboroughkawartha_writer_insert ON public.contact FOR INSERT TO riding_peterboroughkawartha_writer WITH CHECK (division_electoral_district = 'Peterborough—Kawartha');
CREATE POLICY riding_peterboroughkawartha_writer_update ON public.contact FOR UPDATE TO riding_peterboroughkawartha_writer USING (division_electoral_district = 'Peterborough—Kawartha') WITH CHECK (division_electoral_district = 'Peterborough—Kawartha');

GRANT SELECT ON public.contact TO riding_peterboroughkawartha_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_peterboroughkawartha_writer;

-- === Riding: Pickering—Uxbridge ===
CREATE ROLE riding_pickeringuxbridge_reader LOGIN PASSWORD 'JLoj-IK$MrxvvIlz(Eaq';
CREATE ROLE riding_pickeringuxbridge_writer LOGIN PASSWORD 'JLoj-IK$MrxvvIlz(Eaq' INHERIT;
GRANT riding_pickeringuxbridge_reader TO riding_pickeringuxbridge_writer;

CREATE POLICY riding_pickeringuxbridge_reader_read ON public.contact FOR SELECT TO riding_pickeringuxbridge_reader USING (division_electoral_district = 'Pickering—Uxbridge');
CREATE POLICY riding_pickeringuxbridge_writer_insert ON public.contact FOR INSERT TO riding_pickeringuxbridge_writer WITH CHECK (division_electoral_district = 'Pickering—Uxbridge');
CREATE POLICY riding_pickeringuxbridge_writer_update ON public.contact FOR UPDATE TO riding_pickeringuxbridge_writer USING (division_electoral_district = 'Pickering—Uxbridge') WITH CHECK (division_electoral_district = 'Pickering—Uxbridge');

GRANT SELECT ON public.contact TO riding_pickeringuxbridge_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_pickeringuxbridge_writer;

-- === Riding: Renfrew—Nipissing—Pembroke ===
CREATE ROLE riding_renfrewnipissingpembroke_reader LOGIN PASSWORD 'zmw#pcOi1H0z9n2ES)&N';
CREATE ROLE riding_renfrewnipissingpembroke_writer LOGIN PASSWORD 'zmw#pcOi1H0z9n2ES)&N' INHERIT;
GRANT riding_renfrewnipissingpembroke_reader TO riding_renfrewnipissingpembroke_writer;

CREATE POLICY riding_renfrewnipissingpembroke_reader_read ON public.contact FOR SELECT TO riding_renfrewnipissingpembroke_reader USING (division_electoral_district = 'Renfrew—Nipissing—Pembroke');
CREATE POLICY riding_renfrewnipissingpembroke_writer_insert ON public.contact FOR INSERT TO riding_renfrewnipissingpembroke_writer WITH CHECK (division_electoral_district = 'Renfrew—Nipissing—Pembroke');
CREATE POLICY riding_renfrewnipissingpembroke_writer_update ON public.contact FOR UPDATE TO riding_renfrewnipissingpembroke_writer USING (division_electoral_district = 'Renfrew—Nipissing—Pembroke') WITH CHECK (division_electoral_district = 'Renfrew—Nipissing—Pembroke');

GRANT SELECT ON public.contact TO riding_renfrewnipissingpembroke_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_renfrewnipissingpembroke_writer;

-- === Riding: Richmond Hill ===
CREATE ROLE riding_richmondhill_reader LOGIN PASSWORD 'hQ!Sg=o_yn6bDl)H&NOQ';
CREATE ROLE riding_richmondhill_writer LOGIN PASSWORD 'hQ!Sg=o_yn6bDl)H&NOQ' INHERIT;
GRANT riding_richmondhill_reader TO riding_richmondhill_writer;

CREATE POLICY riding_richmondhill_reader_read ON public.contact FOR SELECT TO riding_richmondhill_reader USING (division_electoral_district = 'Richmond Hill');
CREATE POLICY riding_richmondhill_writer_insert ON public.contact FOR INSERT TO riding_richmondhill_writer WITH CHECK (division_electoral_district = 'Richmond Hill');
CREATE POLICY riding_richmondhill_writer_update ON public.contact FOR UPDATE TO riding_richmondhill_writer USING (division_electoral_district = 'Richmond Hill') WITH CHECK (division_electoral_district = 'Richmond Hill');

GRANT SELECT ON public.contact TO riding_richmondhill_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_richmondhill_writer;

-- === Riding: Sarnia—Lambton ===
CREATE ROLE riding_sarnialambton_reader LOGIN PASSWORD 'lO=fh&Bb0ETu_ni_ejr_';
CREATE ROLE riding_sarnialambton_writer LOGIN PASSWORD 'lO=fh&Bb0ETu_ni_ejr_' INHERIT;
GRANT riding_sarnialambton_reader TO riding_sarnialambton_writer;

CREATE POLICY riding_sarnialambton_reader_read ON public.contact FOR SELECT TO riding_sarnialambton_reader USING (division_electoral_district = 'Sarnia—Lambton');
CREATE POLICY riding_sarnialambton_writer_insert ON public.contact FOR INSERT TO riding_sarnialambton_writer WITH CHECK (division_electoral_district = 'Sarnia—Lambton');
CREATE POLICY riding_sarnialambton_writer_update ON public.contact FOR UPDATE TO riding_sarnialambton_writer USING (division_electoral_district = 'Sarnia—Lambton') WITH CHECK (division_electoral_district = 'Sarnia—Lambton');

GRANT SELECT ON public.contact TO riding_sarnialambton_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_sarnialambton_writer;

-- === Riding: Sault Ste. Marie ===
CREATE ROLE riding_saultstemarie_reader LOGIN PASSWORD '5@Ad2qQZ$ZyqrUiG)BZx';
CREATE ROLE riding_saultstemarie_writer LOGIN PASSWORD '5@Ad2qQZ$ZyqrUiG)BZx' INHERIT;
GRANT riding_saultstemarie_reader TO riding_saultstemarie_writer;

CREATE POLICY riding_saultstemarie_reader_read ON public.contact FOR SELECT TO riding_saultstemarie_reader USING (division_electoral_district = 'Sault Ste. Marie');
CREATE POLICY riding_saultstemarie_writer_insert ON public.contact FOR INSERT TO riding_saultstemarie_writer WITH CHECK (division_electoral_district = 'Sault Ste. Marie');
CREATE POLICY riding_saultstemarie_writer_update ON public.contact FOR UPDATE TO riding_saultstemarie_writer USING (division_electoral_district = 'Sault Ste. Marie') WITH CHECK (division_electoral_district = 'Sault Ste. Marie');

GRANT SELECT ON public.contact TO riding_saultstemarie_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_saultstemarie_writer;

-- === Riding: Scarborough Centre ===
CREATE ROLE riding_scarboroughcentre_reader LOGIN PASSWORD 'Duoh%LyIka2gL-(x7XP@';
CREATE ROLE riding_scarboroughcentre_writer LOGIN PASSWORD 'Duoh%LyIka2gL-(x7XP@' INHERIT;
GRANT riding_scarboroughcentre_reader TO riding_scarboroughcentre_writer;

CREATE POLICY riding_scarboroughcentre_reader_read ON public.contact FOR SELECT TO riding_scarboroughcentre_reader USING (division_electoral_district = 'Scarborough Centre');
CREATE POLICY riding_scarboroughcentre_writer_insert ON public.contact FOR INSERT TO riding_scarboroughcentre_writer WITH CHECK (division_electoral_district = 'Scarborough Centre');
CREATE POLICY riding_scarboroughcentre_writer_update ON public.contact FOR UPDATE TO riding_scarboroughcentre_writer USING (division_electoral_district = 'Scarborough Centre') WITH CHECK (division_electoral_district = 'Scarborough Centre');

GRANT SELECT ON public.contact TO riding_scarboroughcentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_scarboroughcentre_writer;

-- === Riding: Scarborough North ===
CREATE ROLE riding_scarboroughnorth_reader LOGIN PASSWORD '3#NM5u0rkP1pS@ImPYDy';
CREATE ROLE riding_scarboroughnorth_writer LOGIN PASSWORD '3#NM5u0rkP1pS@ImPYDy' INHERIT;
GRANT riding_scarboroughnorth_reader TO riding_scarboroughnorth_writer;

CREATE POLICY riding_scarboroughnorth_reader_read ON public.contact FOR SELECT TO riding_scarboroughnorth_reader USING (division_electoral_district = 'Scarborough North');
CREATE POLICY riding_scarboroughnorth_writer_insert ON public.contact FOR INSERT TO riding_scarboroughnorth_writer WITH CHECK (division_electoral_district = 'Scarborough North');
CREATE POLICY riding_scarboroughnorth_writer_update ON public.contact FOR UPDATE TO riding_scarboroughnorth_writer USING (division_electoral_district = 'Scarborough North') WITH CHECK (division_electoral_district = 'Scarborough North');

GRANT SELECT ON public.contact TO riding_scarboroughnorth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_scarboroughnorth_writer;

-- === Riding: Scarborough Southwest ===
CREATE ROLE riding_scarboroughsouthwest_reader LOGIN PASSWORD 'IB$aim-FCF7^YIe0GXBg';
CREATE ROLE riding_scarboroughsouthwest_writer LOGIN PASSWORD 'IB$aim-FCF7^YIe0GXBg' INHERIT;
GRANT riding_scarboroughsouthwest_reader TO riding_scarboroughsouthwest_writer;

CREATE POLICY riding_scarboroughsouthwest_reader_read ON public.contact FOR SELECT TO riding_scarboroughsouthwest_reader USING (division_electoral_district = 'Scarborough Southwest');
CREATE POLICY riding_scarboroughsouthwest_writer_insert ON public.contact FOR INSERT TO riding_scarboroughsouthwest_writer WITH CHECK (division_electoral_district = 'Scarborough Southwest');
CREATE POLICY riding_scarboroughsouthwest_writer_update ON public.contact FOR UPDATE TO riding_scarboroughsouthwest_writer USING (division_electoral_district = 'Scarborough Southwest') WITH CHECK (division_electoral_district = 'Scarborough Southwest');

GRANT SELECT ON public.contact TO riding_scarboroughsouthwest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_scarboroughsouthwest_writer;

-- === Riding: Scarborough—Agincourt ===
CREATE ROLE riding_scarboroughagincourt_reader LOGIN PASSWORD 'Qg^TM$r9@9$4IZmr(FiP';
CREATE ROLE riding_scarboroughagincourt_writer LOGIN PASSWORD 'Qg^TM$r9@9$4IZmr(FiP' INHERIT;
GRANT riding_scarboroughagincourt_reader TO riding_scarboroughagincourt_writer;

CREATE POLICY riding_scarboroughagincourt_reader_read ON public.contact FOR SELECT TO riding_scarboroughagincourt_reader USING (division_electoral_district = 'Scarborough—Agincourt');
CREATE POLICY riding_scarboroughagincourt_writer_insert ON public.contact FOR INSERT TO riding_scarboroughagincourt_writer WITH CHECK (division_electoral_district = 'Scarborough—Agincourt');
CREATE POLICY riding_scarboroughagincourt_writer_update ON public.contact FOR UPDATE TO riding_scarboroughagincourt_writer USING (division_electoral_district = 'Scarborough—Agincourt') WITH CHECK (division_electoral_district = 'Scarborough—Agincourt');

GRANT SELECT ON public.contact TO riding_scarboroughagincourt_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_scarboroughagincourt_writer;

-- === Riding: Scarborough—Guildwood ===
CREATE ROLE riding_scarboroughguildwood_reader LOGIN PASSWORD 't#MUN0I7Ud-)eNGve4(x';
CREATE ROLE riding_scarboroughguildwood_writer LOGIN PASSWORD 't#MUN0I7Ud-)eNGve4(x' INHERIT;
GRANT riding_scarboroughguildwood_reader TO riding_scarboroughguildwood_writer;

CREATE POLICY riding_scarboroughguildwood_reader_read ON public.contact FOR SELECT TO riding_scarboroughguildwood_reader USING (division_electoral_district = 'Scarborough—Guildwood');
CREATE POLICY riding_scarboroughguildwood_writer_insert ON public.contact FOR INSERT TO riding_scarboroughguildwood_writer WITH CHECK (division_electoral_district = 'Scarborough—Guildwood');
CREATE POLICY riding_scarboroughguildwood_writer_update ON public.contact FOR UPDATE TO riding_scarboroughguildwood_writer USING (division_electoral_district = 'Scarborough—Guildwood') WITH CHECK (division_electoral_district = 'Scarborough—Guildwood');

GRANT SELECT ON public.contact TO riding_scarboroughguildwood_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_scarboroughguildwood_writer;

-- === Riding: Scarborough—Rouge Park ===
CREATE ROLE riding_scarboroughrougepark_reader LOGIN PASSWORD 'cEqTit%B!Wk8P4wGFcTt';
CREATE ROLE riding_scarboroughrougepark_writer LOGIN PASSWORD 'cEqTit%B!Wk8P4wGFcTt' INHERIT;
GRANT riding_scarboroughrougepark_reader TO riding_scarboroughrougepark_writer;

CREATE POLICY riding_scarboroughrougepark_reader_read ON public.contact FOR SELECT TO riding_scarboroughrougepark_reader USING (division_electoral_district = 'Scarborough—Rouge Park');
CREATE POLICY riding_scarboroughrougepark_writer_insert ON public.contact FOR INSERT TO riding_scarboroughrougepark_writer WITH CHECK (division_electoral_district = 'Scarborough—Rouge Park');
CREATE POLICY riding_scarboroughrougepark_writer_update ON public.contact FOR UPDATE TO riding_scarboroughrougepark_writer USING (division_electoral_district = 'Scarborough—Rouge Park') WITH CHECK (division_electoral_district = 'Scarborough—Rouge Park');

GRANT SELECT ON public.contact TO riding_scarboroughrougepark_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_scarboroughrougepark_writer;

-- === Riding: Simcoe North ===
CREATE ROLE riding_simcoenorth_reader LOGIN PASSWORD 'vCa+joCORs$N=B4xrcXw';
CREATE ROLE riding_simcoenorth_writer LOGIN PASSWORD 'vCa+joCORs$N=B4xrcXw' INHERIT;
GRANT riding_simcoenorth_reader TO riding_simcoenorth_writer;

CREATE POLICY riding_simcoenorth_reader_read ON public.contact FOR SELECT TO riding_simcoenorth_reader USING (division_electoral_district = 'Simcoe North');
CREATE POLICY riding_simcoenorth_writer_insert ON public.contact FOR INSERT TO riding_simcoenorth_writer WITH CHECK (division_electoral_district = 'Simcoe North');
CREATE POLICY riding_simcoenorth_writer_update ON public.contact FOR UPDATE TO riding_simcoenorth_writer USING (division_electoral_district = 'Simcoe North') WITH CHECK (division_electoral_district = 'Simcoe North');

GRANT SELECT ON public.contact TO riding_simcoenorth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_simcoenorth_writer;

-- === Riding: Simcoe—Grey ===
CREATE ROLE riding_simcoegrey_reader LOGIN PASSWORD 'qL76ngOyUcjR&B4E6She';
CREATE ROLE riding_simcoegrey_writer LOGIN PASSWORD 'qL76ngOyUcjR&B4E6She' INHERIT;
GRANT riding_simcoegrey_reader TO riding_simcoegrey_writer;

CREATE POLICY riding_simcoegrey_reader_read ON public.contact FOR SELECT TO riding_simcoegrey_reader USING (division_electoral_district = 'Simcoe—Grey');
CREATE POLICY riding_simcoegrey_writer_insert ON public.contact FOR INSERT TO riding_simcoegrey_writer WITH CHECK (division_electoral_district = 'Simcoe—Grey');
CREATE POLICY riding_simcoegrey_writer_update ON public.contact FOR UPDATE TO riding_simcoegrey_writer USING (division_electoral_district = 'Simcoe—Grey') WITH CHECK (division_electoral_district = 'Simcoe—Grey');

GRANT SELECT ON public.contact TO riding_simcoegrey_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_simcoegrey_writer;

-- === Riding: Spadina—Fort York ===
CREATE ROLE riding_spadinafortyork_reader LOGIN PASSWORD '-9Nhmc2phVbB!ka__Xs5';
CREATE ROLE riding_spadinafortyork_writer LOGIN PASSWORD '-9Nhmc2phVbB!ka__Xs5' INHERIT;
GRANT riding_spadinafortyork_reader TO riding_spadinafortyork_writer;

CREATE POLICY riding_spadinafortyork_reader_read ON public.contact FOR SELECT TO riding_spadinafortyork_reader USING (division_electoral_district = 'Spadina—Fort York');
CREATE POLICY riding_spadinafortyork_writer_insert ON public.contact FOR INSERT TO riding_spadinafortyork_writer WITH CHECK (division_electoral_district = 'Spadina—Fort York');
CREATE POLICY riding_spadinafortyork_writer_update ON public.contact FOR UPDATE TO riding_spadinafortyork_writer USING (division_electoral_district = 'Spadina—Fort York') WITH CHECK (division_electoral_district = 'Spadina—Fort York');

GRANT SELECT ON public.contact TO riding_spadinafortyork_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_spadinafortyork_writer;

-- === Riding: St. Catharines ===
CREATE ROLE riding_stcatharines_reader LOGIN PASSWORD '$Du%$S%ch53OlQ9YCT8u';
CREATE ROLE riding_stcatharines_writer LOGIN PASSWORD '$Du%$S%ch53OlQ9YCT8u' INHERIT;
GRANT riding_stcatharines_reader TO riding_stcatharines_writer;

CREATE POLICY riding_stcatharines_reader_read ON public.contact FOR SELECT TO riding_stcatharines_reader USING (division_electoral_district = 'St. Catharines');
CREATE POLICY riding_stcatharines_writer_insert ON public.contact FOR INSERT TO riding_stcatharines_writer WITH CHECK (division_electoral_district = 'St. Catharines');
CREATE POLICY riding_stcatharines_writer_update ON public.contact FOR UPDATE TO riding_stcatharines_writer USING (division_electoral_district = 'St. Catharines') WITH CHECK (division_electoral_district = 'St. Catharines');

GRANT SELECT ON public.contact TO riding_stcatharines_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_stcatharines_writer;

-- === Riding: Stormont—Dundas—South Glengarry ===
CREATE ROLE riding_stormontdundassouthglengarry_reader LOGIN PASSWORD '&x)%+kRpMT6!oZq79b8M';
CREATE ROLE riding_stormontdundassouthglengarry_writer LOGIN PASSWORD '&x)%+kRpMT6!oZq79b8M' INHERIT;
GRANT riding_stormontdundassouthglengarry_reader TO riding_stormontdundassouthglengarry_writer;

CREATE POLICY riding_stormontdundassouthglengarry_reader_read ON public.contact FOR SELECT TO riding_stormontdundassouthglengarry_reader USING (division_electoral_district = 'Stormont—Dundas—South Glengarry');
CREATE POLICY riding_stormontdundassouthglengarry_writer_insert ON public.contact FOR INSERT TO riding_stormontdundassouthglengarry_writer WITH CHECK (division_electoral_district = 'Stormont—Dundas—South Glengarry');
CREATE POLICY riding_stormontdundassouthglengarry_writer_update ON public.contact FOR UPDATE TO riding_stormontdundassouthglengarry_writer USING (division_electoral_district = 'Stormont—Dundas—South Glengarry') WITH CHECK (division_electoral_district = 'Stormont—Dundas—South Glengarry');

GRANT SELECT ON public.contact TO riding_stormontdundassouthglengarry_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_stormontdundassouthglengarry_writer;

-- === Riding: Sudbury ===
CREATE ROLE riding_sudbury_reader LOGIN PASSWORD 'sa+7Dpzv@(hEV-X8PlT$';
CREATE ROLE riding_sudbury_writer LOGIN PASSWORD 'sa+7Dpzv@(hEV-X8PlT$' INHERIT;
GRANT riding_sudbury_reader TO riding_sudbury_writer;

CREATE POLICY riding_sudbury_reader_read ON public.contact FOR SELECT TO riding_sudbury_reader USING (division_electoral_district = 'Sudbury');
CREATE POLICY riding_sudbury_writer_insert ON public.contact FOR INSERT TO riding_sudbury_writer WITH CHECK (division_electoral_district = 'Sudbury');
CREATE POLICY riding_sudbury_writer_update ON public.contact FOR UPDATE TO riding_sudbury_writer USING (division_electoral_district = 'Sudbury') WITH CHECK (division_electoral_district = 'Sudbury');

GRANT SELECT ON public.contact TO riding_sudbury_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_sudbury_writer;

-- === Riding: Thornhill ===
CREATE ROLE riding_thornhill_reader LOGIN PASSWORD 'jnyr(G+%uP)3%txTmuUw';
CREATE ROLE riding_thornhill_writer LOGIN PASSWORD 'jnyr(G+%uP)3%txTmuUw' INHERIT;
GRANT riding_thornhill_reader TO riding_thornhill_writer;

CREATE POLICY riding_thornhill_reader_read ON public.contact FOR SELECT TO riding_thornhill_reader USING (division_electoral_district = 'Thornhill');
CREATE POLICY riding_thornhill_writer_insert ON public.contact FOR INSERT TO riding_thornhill_writer WITH CHECK (division_electoral_district = 'Thornhill');
CREATE POLICY riding_thornhill_writer_update ON public.contact FOR UPDATE TO riding_thornhill_writer USING (division_electoral_district = 'Thornhill') WITH CHECK (division_electoral_district = 'Thornhill');

GRANT SELECT ON public.contact TO riding_thornhill_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_thornhill_writer;

-- === Riding: Thunder Bay—Atikokan ===
CREATE ROLE riding_thunderbayatikokan_reader LOGIN PASSWORD '9%5DMzL0WEt)ej%$%l=n';
CREATE ROLE riding_thunderbayatikokan_writer LOGIN PASSWORD '9%5DMzL0WEt)ej%$%l=n' INHERIT;
GRANT riding_thunderbayatikokan_reader TO riding_thunderbayatikokan_writer;

CREATE POLICY riding_thunderbayatikokan_reader_read ON public.contact FOR SELECT TO riding_thunderbayatikokan_reader USING (division_electoral_district = 'Thunder Bay—Atikokan');
CREATE POLICY riding_thunderbayatikokan_writer_insert ON public.contact FOR INSERT TO riding_thunderbayatikokan_writer WITH CHECK (division_electoral_district = 'Thunder Bay—Atikokan');
CREATE POLICY riding_thunderbayatikokan_writer_update ON public.contact FOR UPDATE TO riding_thunderbayatikokan_writer USING (division_electoral_district = 'Thunder Bay—Atikokan') WITH CHECK (division_electoral_district = 'Thunder Bay—Atikokan');

GRANT SELECT ON public.contact TO riding_thunderbayatikokan_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_thunderbayatikokan_writer;

-- === Riding: Thunder Bay—Superior North ===
CREATE ROLE riding_thunderbaysuperiornorth_reader LOGIN PASSWORD 'S5EAhxj79g^xhLKuZXMF';
CREATE ROLE riding_thunderbaysuperiornorth_writer LOGIN PASSWORD 'S5EAhxj79g^xhLKuZXMF' INHERIT;
GRANT riding_thunderbaysuperiornorth_reader TO riding_thunderbaysuperiornorth_writer;

CREATE POLICY riding_thunderbaysuperiornorth_reader_read ON public.contact FOR SELECT TO riding_thunderbaysuperiornorth_reader USING (division_electoral_district = 'Thunder Bay—Superior North');
CREATE POLICY riding_thunderbaysuperiornorth_writer_insert ON public.contact FOR INSERT TO riding_thunderbaysuperiornorth_writer WITH CHECK (division_electoral_district = 'Thunder Bay—Superior North');
CREATE POLICY riding_thunderbaysuperiornorth_writer_update ON public.contact FOR UPDATE TO riding_thunderbaysuperiornorth_writer USING (division_electoral_district = 'Thunder Bay—Superior North') WITH CHECK (division_electoral_district = 'Thunder Bay—Superior North');

GRANT SELECT ON public.contact TO riding_thunderbaysuperiornorth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_thunderbaysuperiornorth_writer;

-- === Riding: Timiskaming—Cochrane ===
CREATE ROLE riding_timiskamingcochrane_reader LOGIN PASSWORD '=nAiLJzfN6_HUDS!M$82';
CREATE ROLE riding_timiskamingcochrane_writer LOGIN PASSWORD '=nAiLJzfN6_HUDS!M$82' INHERIT;
GRANT riding_timiskamingcochrane_reader TO riding_timiskamingcochrane_writer;

CREATE POLICY riding_timiskamingcochrane_reader_read ON public.contact FOR SELECT TO riding_timiskamingcochrane_reader USING (division_electoral_district = 'Timiskaming—Cochrane');
CREATE POLICY riding_timiskamingcochrane_writer_insert ON public.contact FOR INSERT TO riding_timiskamingcochrane_writer WITH CHECK (division_electoral_district = 'Timiskaming—Cochrane');
CREATE POLICY riding_timiskamingcochrane_writer_update ON public.contact FOR UPDATE TO riding_timiskamingcochrane_writer USING (division_electoral_district = 'Timiskaming—Cochrane') WITH CHECK (division_electoral_district = 'Timiskaming—Cochrane');

GRANT SELECT ON public.contact TO riding_timiskamingcochrane_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_timiskamingcochrane_writer;

-- === Riding: Timmins ===
CREATE ROLE riding_timmins_reader LOGIN PASSWORD '$7py1t0iN+ewMDMazMnp';
CREATE ROLE riding_timmins_writer LOGIN PASSWORD '$7py1t0iN+ewMDMazMnp' INHERIT;
GRANT riding_timmins_reader TO riding_timmins_writer;

CREATE POLICY riding_timmins_reader_read ON public.contact FOR SELECT TO riding_timmins_reader USING (division_electoral_district = 'Timmins');
CREATE POLICY riding_timmins_writer_insert ON public.contact FOR INSERT TO riding_timmins_writer WITH CHECK (division_electoral_district = 'Timmins');
CREATE POLICY riding_timmins_writer_update ON public.contact FOR UPDATE TO riding_timmins_writer USING (division_electoral_district = 'Timmins') WITH CHECK (division_electoral_district = 'Timmins');

GRANT SELECT ON public.contact TO riding_timmins_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_timmins_writer;

-- === Riding: Toronto Centre ===
CREATE ROLE riding_torontocentre_reader LOGIN PASSWORD '#$5Pe(d$pcpJk2-JtWpv';
CREATE ROLE riding_torontocentre_writer LOGIN PASSWORD '#$5Pe(d$pcpJk2-JtWpv' INHERIT;
GRANT riding_torontocentre_reader TO riding_torontocentre_writer;

CREATE POLICY riding_torontocentre_reader_read ON public.contact FOR SELECT TO riding_torontocentre_reader USING (division_electoral_district = 'Toronto Centre');
CREATE POLICY riding_torontocentre_writer_insert ON public.contact FOR INSERT TO riding_torontocentre_writer WITH CHECK (division_electoral_district = 'Toronto Centre');
CREATE POLICY riding_torontocentre_writer_update ON public.contact FOR UPDATE TO riding_torontocentre_writer USING (division_electoral_district = 'Toronto Centre') WITH CHECK (division_electoral_district = 'Toronto Centre');

GRANT SELECT ON public.contact TO riding_torontocentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_torontocentre_writer;

-- === Riding: Toronto—Danforth ===
CREATE ROLE riding_torontodanforth_reader LOGIN PASSWORD 'w&PfV(Q=g%Fl^Ebf(Y4)';
CREATE ROLE riding_torontodanforth_writer LOGIN PASSWORD 'w&PfV(Q=g%Fl^Ebf(Y4)' INHERIT;
GRANT riding_torontodanforth_reader TO riding_torontodanforth_writer;

CREATE POLICY riding_torontodanforth_reader_read ON public.contact FOR SELECT TO riding_torontodanforth_reader USING (division_electoral_district = 'Toronto—Danforth');
CREATE POLICY riding_torontodanforth_writer_insert ON public.contact FOR INSERT TO riding_torontodanforth_writer WITH CHECK (division_electoral_district = 'Toronto—Danforth');
CREATE POLICY riding_torontodanforth_writer_update ON public.contact FOR UPDATE TO riding_torontodanforth_writer USING (division_electoral_district = 'Toronto—Danforth') WITH CHECK (division_electoral_district = 'Toronto—Danforth');

GRANT SELECT ON public.contact TO riding_torontodanforth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_torontodanforth_writer;

-- === Riding: Toronto—St. Paul's ===
CREATE ROLE riding_torontostpauls_reader LOGIN PASSWORD '6(bqN6FBGXS17o1TyAuD';
CREATE ROLE riding_torontostpauls_writer LOGIN PASSWORD '6(bqN6FBGXS17o1TyAuD' INHERIT;
GRANT riding_torontostpauls_reader TO riding_torontostpauls_writer;

CREATE POLICY riding_torontostpauls_reader_read ON public.contact FOR SELECT TO riding_torontostpauls_reader USING (division_electoral_district = 'Toronto—St. Paul's');
CREATE POLICY riding_torontostpauls_writer_insert ON public.contact FOR INSERT TO riding_torontostpauls_writer WITH CHECK (division_electoral_district = 'Toronto—St. Paul's');
CREATE POLICY riding_torontostpauls_writer_update ON public.contact FOR UPDATE TO riding_torontostpauls_writer USING (division_electoral_district = 'Toronto—St. Paul's') WITH CHECK (division_electoral_district = 'Toronto—St. Paul's');

GRANT SELECT ON public.contact TO riding_torontostpauls_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_torontostpauls_writer;

-- === Riding: University—Rosedale ===
CREATE ROLE riding_universityrosedale_reader LOGIN PASSWORD '(NUPcT$%)4jU1I#2%K4n';
CREATE ROLE riding_universityrosedale_writer LOGIN PASSWORD '(NUPcT$%)4jU1I#2%K4n' INHERIT;
GRANT riding_universityrosedale_reader TO riding_universityrosedale_writer;

CREATE POLICY riding_universityrosedale_reader_read ON public.contact FOR SELECT TO riding_universityrosedale_reader USING (division_electoral_district = 'University—Rosedale');
CREATE POLICY riding_universityrosedale_writer_insert ON public.contact FOR INSERT TO riding_universityrosedale_writer WITH CHECK (division_electoral_district = 'University—Rosedale');
CREATE POLICY riding_universityrosedale_writer_update ON public.contact FOR UPDATE TO riding_universityrosedale_writer USING (division_electoral_district = 'University—Rosedale') WITH CHECK (division_electoral_district = 'University—Rosedale');

GRANT SELECT ON public.contact TO riding_universityrosedale_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_universityrosedale_writer;

-- === Riding: Vaughan—Woodbridge ===
CREATE ROLE riding_vaughanwoodbridge_reader LOGIN PASSWORD 'BEikthD%X+VLE8VU&4Sb';
CREATE ROLE riding_vaughanwoodbridge_writer LOGIN PASSWORD 'BEikthD%X+VLE8VU&4Sb' INHERIT;
GRANT riding_vaughanwoodbridge_reader TO riding_vaughanwoodbridge_writer;

CREATE POLICY riding_vaughanwoodbridge_reader_read ON public.contact FOR SELECT TO riding_vaughanwoodbridge_reader USING (division_electoral_district = 'Vaughan—Woodbridge');
CREATE POLICY riding_vaughanwoodbridge_writer_insert ON public.contact FOR INSERT TO riding_vaughanwoodbridge_writer WITH CHECK (division_electoral_district = 'Vaughan—Woodbridge');
CREATE POLICY riding_vaughanwoodbridge_writer_update ON public.contact FOR UPDATE TO riding_vaughanwoodbridge_writer USING (division_electoral_district = 'Vaughan—Woodbridge') WITH CHECK (division_electoral_district = 'Vaughan—Woodbridge');

GRANT SELECT ON public.contact TO riding_vaughanwoodbridge_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_vaughanwoodbridge_writer;

-- === Riding: Waterloo ===
CREATE ROLE riding_waterloo_reader LOGIN PASSWORD 'qQ$HZQ$@8Z_mL#wXnA&(';
CREATE ROLE riding_waterloo_writer LOGIN PASSWORD 'qQ$HZQ$@8Z_mL#wXnA&(' INHERIT;
GRANT riding_waterloo_reader TO riding_waterloo_writer;

CREATE POLICY riding_waterloo_reader_read ON public.contact FOR SELECT TO riding_waterloo_reader USING (division_electoral_district = 'Waterloo');
CREATE POLICY riding_waterloo_writer_insert ON public.contact FOR INSERT TO riding_waterloo_writer WITH CHECK (division_electoral_district = 'Waterloo');
CREATE POLICY riding_waterloo_writer_update ON public.contact FOR UPDATE TO riding_waterloo_writer USING (division_electoral_district = 'Waterloo') WITH CHECK (division_electoral_district = 'Waterloo');

GRANT SELECT ON public.contact TO riding_waterloo_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_waterloo_writer;

-- === Riding: Wellington—Halton Hills ===
CREATE ROLE riding_wellingtonhaltonhills_reader LOGIN PASSWORD 'hi!IE2TSAA-i&1vGoLD3';
CREATE ROLE riding_wellingtonhaltonhills_writer LOGIN PASSWORD 'hi!IE2TSAA-i&1vGoLD3' INHERIT;
GRANT riding_wellingtonhaltonhills_reader TO riding_wellingtonhaltonhills_writer;

CREATE POLICY riding_wellingtonhaltonhills_reader_read ON public.contact FOR SELECT TO riding_wellingtonhaltonhills_reader USING (division_electoral_district = 'Wellington—Halton Hills');
CREATE POLICY riding_wellingtonhaltonhills_writer_insert ON public.contact FOR INSERT TO riding_wellingtonhaltonhills_writer WITH CHECK (division_electoral_district = 'Wellington—Halton Hills');
CREATE POLICY riding_wellingtonhaltonhills_writer_update ON public.contact FOR UPDATE TO riding_wellingtonhaltonhills_writer USING (division_electoral_district = 'Wellington—Halton Hills') WITH CHECK (division_electoral_district = 'Wellington—Halton Hills');

GRANT SELECT ON public.contact TO riding_wellingtonhaltonhills_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_wellingtonhaltonhills_writer;

-- === Riding: Whitby ===
CREATE ROLE riding_whitby_reader LOGIN PASSWORD '6O&t+RfAvo6huOG)s*ex';
CREATE ROLE riding_whitby_writer LOGIN PASSWORD '6O&t+RfAvo6huOG)s*ex' INHERIT;
GRANT riding_whitby_reader TO riding_whitby_writer;

CREATE POLICY riding_whitby_reader_read ON public.contact FOR SELECT TO riding_whitby_reader USING (division_electoral_district = 'Whitby');
CREATE POLICY riding_whitby_writer_insert ON public.contact FOR INSERT TO riding_whitby_writer WITH CHECK (division_electoral_district = 'Whitby');
CREATE POLICY riding_whitby_writer_update ON public.contact FOR UPDATE TO riding_whitby_writer USING (division_electoral_district = 'Whitby') WITH CHECK (division_electoral_district = 'Whitby');

GRANT SELECT ON public.contact TO riding_whitby_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_whitby_writer;

-- === Riding: Willowdale ===
CREATE ROLE riding_willowdale_reader LOGIN PASSWORD 'ScX+Me00iKZ-LDNJx9al';
CREATE ROLE riding_willowdale_writer LOGIN PASSWORD 'ScX+Me00iKZ-LDNJx9al' INHERIT;
GRANT riding_willowdale_reader TO riding_willowdale_writer;

CREATE POLICY riding_willowdale_reader_read ON public.contact FOR SELECT TO riding_willowdale_reader USING (division_electoral_district = 'Willowdale');
CREATE POLICY riding_willowdale_writer_insert ON public.contact FOR INSERT TO riding_willowdale_writer WITH CHECK (division_electoral_district = 'Willowdale');
CREATE POLICY riding_willowdale_writer_update ON public.contact FOR UPDATE TO riding_willowdale_writer USING (division_electoral_district = 'Willowdale') WITH CHECK (division_electoral_district = 'Willowdale');

GRANT SELECT ON public.contact TO riding_willowdale_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_willowdale_writer;

-- === Riding: Windsor West ===
CREATE ROLE riding_windsorwest_reader LOGIN PASSWORD '*NNP$iV!@M9q+sx%yq=Q';
CREATE ROLE riding_windsorwest_writer LOGIN PASSWORD '*NNP$iV!@M9q+sx%yq=Q' INHERIT;
GRANT riding_windsorwest_reader TO riding_windsorwest_writer;

CREATE POLICY riding_windsorwest_reader_read ON public.contact FOR SELECT TO riding_windsorwest_reader USING (division_electoral_district = 'Windsor West');
CREATE POLICY riding_windsorwest_writer_insert ON public.contact FOR INSERT TO riding_windsorwest_writer WITH CHECK (division_electoral_district = 'Windsor West');
CREATE POLICY riding_windsorwest_writer_update ON public.contact FOR UPDATE TO riding_windsorwest_writer USING (division_electoral_district = 'Windsor West') WITH CHECK (division_electoral_district = 'Windsor West');

GRANT SELECT ON public.contact TO riding_windsorwest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_windsorwest_writer;

-- === Riding: Windsor—Tecumseh ===
CREATE ROLE riding_windsortecumseh_reader LOGIN PASSWORD 'zMbPN-$RWnVUHQl7v*+_';
CREATE ROLE riding_windsortecumseh_writer LOGIN PASSWORD 'zMbPN-$RWnVUHQl7v*+_' INHERIT;
GRANT riding_windsortecumseh_reader TO riding_windsortecumseh_writer;

CREATE POLICY riding_windsortecumseh_reader_read ON public.contact FOR SELECT TO riding_windsortecumseh_reader USING (division_electoral_district = 'Windsor—Tecumseh');
CREATE POLICY riding_windsortecumseh_writer_insert ON public.contact FOR INSERT TO riding_windsortecumseh_writer WITH CHECK (division_electoral_district = 'Windsor—Tecumseh');
CREATE POLICY riding_windsortecumseh_writer_update ON public.contact FOR UPDATE TO riding_windsortecumseh_writer USING (division_electoral_district = 'Windsor—Tecumseh') WITH CHECK (division_electoral_district = 'Windsor—Tecumseh');

GRANT SELECT ON public.contact TO riding_windsortecumseh_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_windsortecumseh_writer;

-- === Riding: York Centre ===
CREATE ROLE riding_yorkcentre_reader LOGIN PASSWORD 'Y3PWvv$mRN-kXe4WOAS!';
CREATE ROLE riding_yorkcentre_writer LOGIN PASSWORD 'Y3PWvv$mRN-kXe4WOAS!' INHERIT;
GRANT riding_yorkcentre_reader TO riding_yorkcentre_writer;

CREATE POLICY riding_yorkcentre_reader_read ON public.contact FOR SELECT TO riding_yorkcentre_reader USING (division_electoral_district = 'York Centre');
CREATE POLICY riding_yorkcentre_writer_insert ON public.contact FOR INSERT TO riding_yorkcentre_writer WITH CHECK (division_electoral_district = 'York Centre');
CREATE POLICY riding_yorkcentre_writer_update ON public.contact FOR UPDATE TO riding_yorkcentre_writer USING (division_electoral_district = 'York Centre') WITH CHECK (division_electoral_district = 'York Centre');

GRANT SELECT ON public.contact TO riding_yorkcentre_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_yorkcentre_writer;

-- === Riding: York South—Weston ===
CREATE ROLE riding_yorksouthweston_reader LOGIN PASSWORD 'g0OiLhrH#mpq%899ZQ*w';
CREATE ROLE riding_yorksouthweston_writer LOGIN PASSWORD 'g0OiLhrH#mpq%899ZQ*w' INHERIT;
GRANT riding_yorksouthweston_reader TO riding_yorksouthweston_writer;

CREATE POLICY riding_yorksouthweston_reader_read ON public.contact FOR SELECT TO riding_yorksouthweston_reader USING (division_electoral_district = 'York South—Weston');
CREATE POLICY riding_yorksouthweston_writer_insert ON public.contact FOR INSERT TO riding_yorksouthweston_writer WITH CHECK (division_electoral_district = 'York South—Weston');
CREATE POLICY riding_yorksouthweston_writer_update ON public.contact FOR UPDATE TO riding_yorksouthweston_writer USING (division_electoral_district = 'York South—Weston') WITH CHECK (division_electoral_district = 'York South—Weston');

GRANT SELECT ON public.contact TO riding_yorksouthweston_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_yorksouthweston_writer;

-- === Riding: York—Simcoe ===
CREATE ROLE riding_yorksimcoe_reader LOGIN PASSWORD '_TX%pK$1UnRoX9OY8A2#';
CREATE ROLE riding_yorksimcoe_writer LOGIN PASSWORD '_TX%pK$1UnRoX9OY8A2#' INHERIT;
GRANT riding_yorksimcoe_reader TO riding_yorksimcoe_writer;

CREATE POLICY riding_yorksimcoe_reader_read ON public.contact FOR SELECT TO riding_yorksimcoe_reader USING (division_electoral_district = 'York—Simcoe');
CREATE POLICY riding_yorksimcoe_writer_insert ON public.contact FOR INSERT TO riding_yorksimcoe_writer WITH CHECK (division_electoral_district = 'York—Simcoe');
CREATE POLICY riding_yorksimcoe_writer_update ON public.contact FOR UPDATE TO riding_yorksimcoe_writer USING (division_electoral_district = 'York—Simcoe') WITH CHECK (division_electoral_district = 'York—Simcoe');

GRANT SELECT ON public.contact TO riding_yorksimcoe_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO riding_yorksimcoe_writer;

-- === Region: central_east ===
CREATE ROLE region_centraleast_reader LOGIN PASSWORD 'AV=6uNkp)pD$OnCTC1fp';
CREATE ROLE region_centraleast_writer LOGIN PASSWORD 'AV=6uNkp)pD$OnCTC1fp' INHERIT;
GRANT region_centraleast_reader TO region_centraleast_writer;

-- Contact table policies
CREATE POLICY region_centraleast_reader_contact_read ON public.contact FOR SELECT TO region_centraleast_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_east'));
CREATE POLICY region_centraleast_writer_contact_insert ON public.contact FOR INSERT TO region_centraleast_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_east'));
CREATE POLICY region_centraleast_writer_contact_update ON public.contact FOR UPDATE TO region_centraleast_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_east')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_east'));

-- Division table policies
CREATE POLICY region_centraleast_reader_division_read ON public.division_electoral_district FOR SELECT TO region_centraleast_reader USING (olp_region = 'central_east');

GRANT SELECT ON public.contact TO region_centraleast_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_centraleast_writer;
GRANT SELECT ON public.division_electoral_district TO region_centraleast_reader;
GRANT SELECT ON public.division_electoral_district TO region_centraleast_writer;

-- === Region: central_north ===
CREATE ROLE region_centralnorth_reader LOGIN PASSWORD '_UQolZnH7I+c8W$Ot+Jd';
CREATE ROLE region_centralnorth_writer LOGIN PASSWORD '_UQolZnH7I+c8W$Ot+Jd' INHERIT;
GRANT region_centralnorth_reader TO region_centralnorth_writer;

-- Contact table policies
CREATE POLICY region_centralnorth_reader_contact_read ON public.contact FOR SELECT TO region_centralnorth_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_north'));
CREATE POLICY region_centralnorth_writer_contact_insert ON public.contact FOR INSERT TO region_centralnorth_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_north'));
CREATE POLICY region_centralnorth_writer_contact_update ON public.contact FOR UPDATE TO region_centralnorth_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_north')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_north'));

-- Division table policies
CREATE POLICY region_centralnorth_reader_division_read ON public.division_electoral_district FOR SELECT TO region_centralnorth_reader USING (olp_region = 'central_north');

GRANT SELECT ON public.contact TO region_centralnorth_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_centralnorth_writer;
GRANT SELECT ON public.division_electoral_district TO region_centralnorth_reader;
GRANT SELECT ON public.division_electoral_district TO region_centralnorth_writer;

-- === Region: central_west ===
CREATE ROLE region_centralwest_reader LOGIN PASSWORD 'ZB9StT5nAPVPpOAI+4sT';
CREATE ROLE region_centralwest_writer LOGIN PASSWORD 'ZB9StT5nAPVPpOAI+4sT' INHERIT;
GRANT region_centralwest_reader TO region_centralwest_writer;

-- Contact table policies
CREATE POLICY region_centralwest_reader_contact_read ON public.contact FOR SELECT TO region_centralwest_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_west'));
CREATE POLICY region_centralwest_writer_contact_insert ON public.contact FOR INSERT TO region_centralwest_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_west'));
CREATE POLICY region_centralwest_writer_contact_update ON public.contact FOR UPDATE TO region_centralwest_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_west')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'central_west'));

-- Division table policies
CREATE POLICY region_centralwest_reader_division_read ON public.division_electoral_district FOR SELECT TO region_centralwest_reader USING (olp_region = 'central_west');

GRANT SELECT ON public.contact TO region_centralwest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_centralwest_writer;
GRANT SELECT ON public.division_electoral_district TO region_centralwest_reader;
GRANT SELECT ON public.division_electoral_district TO region_centralwest_writer;

-- === Region: east ===
CREATE ROLE region_east_reader LOGIN PASSWORD 'l9GGtbOdFdw61A=iUufQ';
CREATE ROLE region_east_writer LOGIN PASSWORD 'l9GGtbOdFdw61A=iUufQ' INHERIT;
GRANT region_east_reader TO region_east_writer;

-- Contact table policies
CREATE POLICY region_east_reader_contact_read ON public.contact FOR SELECT TO region_east_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'east'));
CREATE POLICY region_east_writer_contact_insert ON public.contact FOR INSERT TO region_east_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'east'));
CREATE POLICY region_east_writer_contact_update ON public.contact FOR UPDATE TO region_east_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'east')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'east'));

-- Division table policies
CREATE POLICY region_east_reader_division_read ON public.division_electoral_district FOR SELECT TO region_east_reader USING (olp_region = 'east');

GRANT SELECT ON public.contact TO region_east_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_east_writer;
GRANT SELECT ON public.division_electoral_district TO region_east_reader;
GRANT SELECT ON public.division_electoral_district TO region_east_writer;

-- === Region: north ===
CREATE ROLE region_north_reader LOGIN PASSWORD 'Q!-eHiO1=&^D_+=Jx9*w';
CREATE ROLE region_north_writer LOGIN PASSWORD 'Q!-eHiO1=&^D_+=Jx9*w' INHERIT;
GRANT region_north_reader TO region_north_writer;

-- Contact table policies
CREATE POLICY region_north_reader_contact_read ON public.contact FOR SELECT TO region_north_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'north'));
CREATE POLICY region_north_writer_contact_insert ON public.contact FOR INSERT TO region_north_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'north'));
CREATE POLICY region_north_writer_contact_update ON public.contact FOR UPDATE TO region_north_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'north')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'north'));

-- Division table policies
CREATE POLICY region_north_reader_division_read ON public.division_electoral_district FOR SELECT TO region_north_reader USING (olp_region = 'north');

GRANT SELECT ON public.contact TO region_north_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_north_writer;
GRANT SELECT ON public.division_electoral_district TO region_north_reader;
GRANT SELECT ON public.division_electoral_district TO region_north_writer;

-- === Region: south_central ===
CREATE ROLE region_southcentral_reader LOGIN PASSWORD 'X6Cm7EHxq*7VRYvl-Qb_';
CREATE ROLE region_southcentral_writer LOGIN PASSWORD 'X6Cm7EHxq*7VRYvl-Qb_' INHERIT;
GRANT region_southcentral_reader TO region_southcentral_writer;

-- Contact table policies
CREATE POLICY region_southcentral_reader_contact_read ON public.contact FOR SELECT TO region_southcentral_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_central'));
CREATE POLICY region_southcentral_writer_contact_insert ON public.contact FOR INSERT TO region_southcentral_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_central'));
CREATE POLICY region_southcentral_writer_contact_update ON public.contact FOR UPDATE TO region_southcentral_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_central')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_central'));

-- Division table policies
CREATE POLICY region_southcentral_reader_division_read ON public.division_electoral_district FOR SELECT TO region_southcentral_reader USING (olp_region = 'south_central');

GRANT SELECT ON public.contact TO region_southcentral_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_southcentral_writer;
GRANT SELECT ON public.division_electoral_district TO region_southcentral_reader;
GRANT SELECT ON public.division_electoral_district TO region_southcentral_writer;

-- === Region: south_west ===
CREATE ROLE region_southwest_reader LOGIN PASSWORD 'yFB%5*rH7M56vtL%TrjL';
CREATE ROLE region_southwest_writer LOGIN PASSWORD 'yFB%5*rH7M56vtL%TrjL' INHERIT;
GRANT region_southwest_reader TO region_southwest_writer;

-- Contact table policies
CREATE POLICY region_southwest_reader_contact_read ON public.contact FOR SELECT TO region_southwest_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_west'));
CREATE POLICY region_southwest_writer_contact_insert ON public.contact FOR INSERT TO region_southwest_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_west'));
CREATE POLICY region_southwest_writer_contact_update ON public.contact FOR UPDATE TO region_southwest_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_west')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'south_west'));

-- Division table policies
CREATE POLICY region_southwest_reader_division_read ON public.division_electoral_district FOR SELECT TO region_southwest_reader USING (olp_region = 'south_west');

GRANT SELECT ON public.contact TO region_southwest_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_southwest_writer;
GRANT SELECT ON public.division_electoral_district TO region_southwest_reader;
GRANT SELECT ON public.division_electoral_district TO region_southwest_writer;

-- === Region: toronto_ede ===
CREATE ROLE region_torontoede_reader LOGIN PASSWORD 'OkSf=_IGk6&5NdxbYHS&';
CREATE ROLE region_torontoede_writer LOGIN PASSWORD 'OkSf=_IGk6&5NdxbYHS&' INHERIT;
GRANT region_torontoede_reader TO region_torontoede_writer;

-- Contact table policies
CREATE POLICY region_torontoede_reader_contact_read ON public.contact FOR SELECT TO region_torontoede_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_ede'));
CREATE POLICY region_torontoede_writer_contact_insert ON public.contact FOR INSERT TO region_torontoede_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_ede'));
CREATE POLICY region_torontoede_writer_contact_update ON public.contact FOR UPDATE TO region_torontoede_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_ede')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_ede'));

-- Division table policies
CREATE POLICY region_torontoede_reader_division_read ON public.division_electoral_district FOR SELECT TO region_torontoede_reader USING (olp_region = 'toronto_ede');

GRANT SELECT ON public.contact TO region_torontoede_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_torontoede_writer;
GRANT SELECT ON public.division_electoral_district TO region_torontoede_reader;
GRANT SELECT ON public.division_electoral_district TO region_torontoede_writer;

-- === Region: toronto_yns ===
CREATE ROLE region_torontoyns_reader LOGIN PASSWORD 'E6x%uS6W&PFkhT-Xf82#';
CREATE ROLE region_torontoyns_writer LOGIN PASSWORD 'E6x%uS6W&PFkhT-Xf82#' INHERIT;
GRANT region_torontoyns_reader TO region_torontoyns_writer;

-- Contact table policies
CREATE POLICY region_torontoyns_reader_contact_read ON public.contact FOR SELECT TO region_torontoyns_reader USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_yns'));
CREATE POLICY region_torontoyns_writer_contact_insert ON public.contact FOR INSERT TO region_torontoyns_writer WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_yns'));
CREATE POLICY region_torontoyns_writer_contact_update ON public.contact FOR UPDATE TO region_torontoyns_writer USING (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_yns')) WITH CHECK (EXISTS (SELECT 1 FROM public.division_electoral_district d WHERE d.name = division_electoral_district AND d.olp_region = 'toronto_yns'));

-- Division table policies
CREATE POLICY region_torontoyns_reader_division_read ON public.division_electoral_district FOR SELECT TO region_torontoyns_reader USING (olp_region = 'toronto_yns');

GRANT SELECT ON public.contact TO region_torontoyns_reader;
GRANT SELECT, INSERT, UPDATE ON public.contact TO region_torontoyns_writer;
GRANT SELECT ON public.division_electoral_district TO region_torontoyns_reader;
GRANT SELECT ON public.division_electoral_district TO region_torontoyns_writer;
