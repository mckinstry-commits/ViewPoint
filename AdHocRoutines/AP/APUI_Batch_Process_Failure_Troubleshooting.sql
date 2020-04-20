--Find current batch
select * from APHB where BatchId=6866
--From AP UI Batch Process, user gets error about not allowing 'null' in APUL 'Units.
--Verify items not added to ABLB
select * from APLB where Co=1 and BatchId=6866

--Find appropratie records in APUL & verify null 'Units'
select KeyID,Units,* from APUL where PO='130100497'
select KeyID,Units,* from APUL where PO='130100302' 
select KeyID,Units,* from APUL where PO='1-14289041' 

--Try updating 'Units' to 0.00 to resolve displayed error
update APUL set Units=0.00 where PO='130100497' and Units is null 
update APUL set Units=0.00 where PO='130100302' and Units is null 
update APUL set Units=0.00 where PO='1-14289041' and Units is null 

--Results in error
/*
Msg 245, Level 16, State 1, Line 1
Conversion failed when converting the varchar value '1-14289041' to data type int.
*/

--Attempt same update with PO as numeric (?data type mismatch?)
update APUL set Units=0.00 where PO='130100497' and Units is null 
update APUL set Units=0.00 where PO='130100302' and Units is null 
--Regardless of which APUL record is updated, the [btAPULu] trigger fires the following failure
/*Msg 245, Level 16, State 1, Line 2
Conversion failed when converting the varchar value '1-14289041' to data type int.
*/

--Verify PO Datatpe in all tables/procs/functions/etc
select so.name, sc.name, st.name, sc.length 
from sysobjects so join syscolumns sc on so.id=sc.id join systypes st on sc.xusertype=st.xusertype where sc.name='PO'
and st.name <> 'varchar'

--Script to verify that the APLB records are not present for Batch Processing
Select sum(b.GrossAmt+ case b.TaxType when 2 then 0 else b.TaxAmt end 
		+ case b.MiscYN when 'Y' then b.MiscAmt else 0 end) FROM APLB b with (nolock) 
		where b.Co=1 and b.Mth='11/1/2014' and b.BatchId=6866 and b.BatchSeq=2