-- This script converts tables to a single JSON file for the D3 Repatha case tables.

-- Author: Lingtian "Lindsay" Wan
-- Create Date: 09/14/2016

select row_to_json(x)
from (
  (select array_to_json(array_agg(row_to_json(t))) as nodes
    from (
      select node_type, pmid, cast(pub_year as int), title, journal,
      (
        select array_to_json(array_agg(row_to_json(a)))
          from (
            select full_name from temp_d3_repatha_pmid_auth
              where pmid=p.pmid
          ) a
      ) as authors,
      (
        select array_to_json(array_agg(row_to_json(g)))
        from (
          select grant_num from temp_d3_repatha_pmid_grant_inst b
            where pmid=p.pmid and grant_num != ''
        ) g
      ) as grants,
      (
        select array_to_json(array_agg(row_to_json(i)))
        from (
          select institute_name from temp_d3_repatha_pmid_grant_inst b
            where pmid=p.pmid and institute_name != ''
        ) i
      ) as institutes
      from temp_d3_repatha_pmid_pub p
    ) t)
) x
;
