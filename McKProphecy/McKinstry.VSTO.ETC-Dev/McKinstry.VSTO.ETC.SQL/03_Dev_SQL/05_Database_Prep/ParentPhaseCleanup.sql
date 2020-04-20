--Step 1:  Chop off the Leading Tab  (1112 Rows)
UPDATE JCPM SET udParentPhase = SUBSTRING(udParentPhase,2,30) 
where Substring(udParentPhase,1,1) ='	';

--Step 2:  Chop off the Tab at Character 10  (1112 Rows)
UPDATE JCPM 
SET udParentPhase = CONCAT((SUBSTRING(udParentPhase,1,9)),(SUBSTRING(udParentPhase,11,20)))
where SUBSTRING(udParentPhase,10,1) ='	';

--Step 3:  Fix the 39 rows that have a space as the 6th character   (39)
UPDATE JCPM 
SET udParentPhase = CONCAT((SUBSTRING(udParentPhase,1,5)),'0',(SUBSTRING(udParentPhase,7,25)))
where SUBSTRING(udParentPhase,6,1) =' ';