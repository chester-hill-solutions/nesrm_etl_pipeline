#!/bin/bash
npx supabase login
npx supabase db pull
npx supabase migration up