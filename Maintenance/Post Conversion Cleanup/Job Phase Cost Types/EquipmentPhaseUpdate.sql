
--UPDATE MISSING EQUIPMENT JOB PHASES
INSERT INTO dbo.JCJP
        ( JCCo ,
          Job ,
          PhaseGroup ,
          Phase ,
          Description ,
          Contract ,
          Item ,
          ProjMinPct ,
          ActiveYN 
        )
SELECT j.JCCo, j.Job, 1, '0100-0240-      -   ', 'McKinstry Truck Charge', j.Contract, '               1', 0, 'Y'
FROM dbo.JCJM j
	LEFT OUTER JOIN dbo.JCJP p ON p.JCCo = j.JCCo AND p.Job = j.Job AND p.Phase = '0100-0240-      -   '
WHERE p.Phase IS NULL --OR c.CostType IS NULL
	AND j.JCCo < 100
GROUP BY j.JCCo, j.Job,j.Contract






--UPDATE MISSING EQUIPMENT JOB PHASE COST TYPES
INSERT INTO dbo.JCCH
        ( JCCo ,
          Job ,
          PhaseGroup ,
          Phase ,
          CostType ,
          UM ,
          BillFlag ,
          ItemUnitFlag ,
          PhaseUnitFlag ,
          Plugged ,
          ActiveYN ,
          OrigHours ,
          OrigUnits ,
          OrigCost ,
          SourceStatus 
        )
SELECT j.JCCo, j.Job, 1, '0100-0240-      -   ', 5, 'LS', 'C', 'N','N','N','Y', 0, 0, 0, 'J'
FROM JCJM j 
	LEFT OUTER JOIN dbo.JCJP p ON p.JCCo = j.JCCo AND p.Job = j.Job AND p.Phase = '0100-0240-      -   '
	LEFT OUTER JOIN dbo.JCCH c ON c.JCCo = p.JCCo AND c.Job = p.Job AND c.Phase = p.Phase AND c.CostType = 5
WHERE c.CostType IS NULL
	AND j.JCCo < 100
GROUP BY j.JCCo, j.Job, p.Phase
--ORDER BY j.JCCo, j.Job

