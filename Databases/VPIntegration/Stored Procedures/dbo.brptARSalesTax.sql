SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptARSalesTax    Script Date: 8/28/99 9:32:28 AM ******/
      --Drop proc brptARSalesTax
      CREATE                   proc [dbo].[brptARSalesTax]
      (@ARCo bCompany=1, @BeginTaxCode bTaxCode ='', @EndTaxCode bTaxCode= 'zzzzzzzzz',
       @BeginMth bMonth= '01/01/1950',@EndMth bMonth= '12/1/2049',@NoTaxLines bYN= 'N')
       as
      
   /* Issue 25182 add no locks for performance 9/1/04 JRE */
   /* Issue 129643 add HQCO.Name into last 'insert into #Multilevel' 11/06/08 DML */  
 
      create table #Multilevel
      
      	(Name	varchar (60)		NULL,
      	ARCo	tinyint	NULL,
      	ARTrans	int	NULL,
      	ARLine	int	NULL,
      	Mth	smalldatetime	NULL,
      	TransDate	Smalldatetime NULL,
      	Customer	int	NULL,
      	Invoice	varchar(10)	NULL,
      	CheckNo	varchar(10)	NULL,
      	Description varchar (30) NULL,
      	BaseTaxCode	varchar	(10) NULL,
      	BaseTaxDesc varchar (30)	NULL,
      	MultiLevel varchar (10) NULL,
      	LocalTaxCode varchar (10) NULL,
      	LocalTaxDesc varchar (30) NULL,
      	GLAcct varchar (20) NULL,
      	TaxBasis decimal (12,2) NULL,
      	TaxAmount decimal (12,2) NULL,
      	TaxRate decimal (8,6) NULL,
      	TaxLocalBasisTotal decimal (12,2) NULL,
      	TaxLocalAmountTotal decimal (12,2) NULL,
      	TaxBaseAmountTotal decimal(12,2) NULL,
      	TaxBaseBasisTotal decimal (12,2) NULL,
             DiscOffered decimal (12,2) NULL,
             TaxDisc decimal (12,2) NULL,
             TaxLocalDiscOffTotal decimal (12,2) NULL,
             TaxLocalTaxDiscTotal decimal (12,2) NULL,
             TaxBaseDiscOffTotal decimal (12,2) NULL,
             TaxBaseTaxDiscTotal decimal (12,2) NULL,
    	Amount decimal (12,2) NULL,
    	TotalAmount decimal (12,2) NULL)
      
      
      
      create table #BaseRate
      
      	(TaxGroup        tinyint          NULL,
      	TaxCode         varchar (10)      NULL,
      	OldBaseRate     Decimal(8,6)      NULL,
      	NewBaseRate     Decimal(8,6)	  NULL,
        	EffectiveDate   smalldatetime 	NULL,
              Description	varchar (30)	NULL,
      	GLAcct		varchar(20)	NULL,
      	LocalTaxCode	varchar (10)	NULL)
      
      /* insert OldBaseRate and NewBaseRate Info */
      insert into #BaseRate
        (TaxGroup, TaxCode, OldBaseRate, NewBaseRate,EffectiveDate,Description,GLAcct,LocalTaxCode)
      
        SELECT b.TaxGroup,b.TaxCode,
              OldBaseRate=sum(case when b.MultiLevel='Y'  then x.OldRate else b.OldRate end),
              NewBaseRate=sum(case when  b.MultiLevel='Y' then x.NewRate else b.NewRate end),
              EffectiveDate=(case when b.MultiLevel='Y' then x.EffectiveDate else b.EffectiveDate end),
      	Description=(case when b.MultiLevel='Y' then x.Description else b.Description end),
         	x.GLAcct,LocalTaxCode = x.TaxCode
        FROM HQTX b with (nolock)
        Left Join HQTL a with (nolock) on a.TaxGroup=b.TaxGroup and a.TaxCode=b.TaxCode
        Left Join HQTX x with (nolock) on x.TaxGroup=a.TaxGroup and x.TaxCode=a.TaxLink
      
        GROUP BY
           b.TaxGroup, b.TaxCode,b.MultiLevel,b.EffectiveDate, x.EffectiveDate, b.Description,x.Description,x.GLAcct,x.TaxCode
      
      /* insert Multilevel Code Info */
      insert into #Multilevel
        (Name, ARCo,	ARTrans, ARLine, Mth,TransDate, Customer, Invoice, CheckNo, Description, BaseTaxCode, BaseTaxDesc, 
        MultiLevel, LocalTaxCode, LocalTaxDesc, GLAcct, TaxBasis, TaxAmount,TaxRate,DiscOffered,TaxDisc,Amount)
      	
         SELECT HQCO.Name,ARTL.ARCo, ARTL.ARTrans, ARTL.ARLine, ARTL.Mth,
              ARTH.TransDate, ARTH.Customer,
      	ARTH.Invoice, ARTH.CheckNo, ARTH.Description,
      	BaseTaxCode=base.TaxCode,
      	BaseTaxDesc=base.Description,
      	MultiLevel=base.MultiLevel,
      	LocalTaxCode=case base.MultiLevel when 'Y' then #BaseRate.LocalTaxCode  else #BaseRate.TaxCode end,
      	LocalTaxDesc=case base.MultiLevel when 'Y' then #BaseRate.Description  end,
      	GLAcct=case base.MultiLevel when 'Y' then #BaseRate.GLAcct else base.GLAcct end,
      	ARTL.TaxBasis,
      	ARTL.TaxAmount,
      	/*
      	TaxRate=case  base.MultiLevel when 'Y'
  
      	        then
      	*/
      	TaxRate= case when ARTH.TransDate < isnull(#BaseRate.EffectiveDate,'12/31/2070') then (#BaseRate.OldBaseRate)
      	      	       when ARTH.TransDate >= isnull(#BaseRate.EffectiveDate,'12/31/2070') then (#BaseRate.NewBaseRate)
      	    	 end,
              ARTL.DiscOffered,
              ARTL.TaxDisc, ARTL.Amount
      	 --BeginTaxCode=@BeginTaxCode, EndTaxCode=@EndTaxCode, BeginMth=@BeginMth, EndMth=@EndMth
          FROM ARTL with (nolock) 
      
          Inner Join ARTH  with (nolock) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
          Inner Join HQCO  with (nolock) on ARTL.ARCo=HQCO.HQCo
          Inner Join HQTX base  with (nolock) on base.TaxGroup=ARTL.TaxGroup and base.TaxCode=ARTL.TaxCode
          Inner Join #BaseRate  with (nolock) on #BaseRate.TaxGroup=ARTL.TaxGroup and #BaseRate.TaxCode=ARTL.TaxCode
          /*Full outer Join HQTL on HQTL.TaxGroup = ARTL.TaxGroup and HQTL.TaxCode = ARTL.TaxCode
          Full outer Join HQTX local on local.TaxGroup = HQTL.TaxGroup and local.TaxCode = HQTL.TaxLink*/
      
          WHERE ARTL.ARCo=@ARCo and ARTL.TaxCode>=@BeginTaxCode and ARTL.TaxCode<=@EndTaxCode
          and ARTL.Mth>=@BeginMth and ARTL.Mth<=@EndMth and ARTH.ARTransType Not In ('P','M')
      
      /* insert Total into #Multilevel */
      insert into #Multilevel
      	(ARCo,Name,BaseTaxCode, LocalTaxCode,TaxRate, ARTrans,Mth, TaxLocalBasisTotal,TaxLocalAmountTotal,
              TaxLocalDiscOffTotal, TaxLocalTaxDiscTotal)
      	
      	/*SELECT DISTINCT   ARCo,Name, BaseTaxCode,  LocalTaxCode, TaxRate, ARTrans,Mth, TaxBasis, TaxAmount 
              FROM #Multilevel*/
      	Select ARCo, Name, BaseTaxCode, LocalTaxCode, TaxRate, ARTrans, Mth, sum(TaxBasis), sum(TaxAmount),
      	sum(DiscOffered), sum(TaxDisc) 
             From #Multilevel Group By ARCo, Name, BaseTaxCode, LocalTaxCode, Mth, TaxRate, ARTrans
      	
      insert into #Multilevel
      	(ARCo, Name, BaseTaxCode, ARTrans, Mth, TaxBaseBasisTotal, TaxBaseAmountTotal,
              TaxBaseDiscOffTotal, TaxBaseTaxDiscTotal, TotalAmount)
      	/*Select Distinct ARCo, Name, BaseTaxCode, ARTrans, Mth, TaxBasis, TaxAmount
      	From #Multilevel*/
      	Select ARTL.ARCo, HQCO.Name, TaxCode, ARTL.ARTrans, ARTL.Mth, sum(TaxBasis), sum(TaxAmount),
             sum(DiscOffered), sum(TaxDisc), sum(Amount)
      	From ARTL  with (nolock) 
      	Join ARTH  with (nolock) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
      	Join HQCO  with (nolock) on HQCO.HQCo=ARTL.ARCo
      	WHERE HQCO.HQCo=@ARCo
   		and ARTL.ARCo=@ARCo and ARTL.TaxCode between @BeginTaxCode and @EndTaxCode
   		and ARTL.Mth between @BeginMth and @EndMth 
   		and ARTH.ARCo=@ARCo and ARTH.Mth between @BeginMth and @EndMth 
   		and ARTH.ARTransType Not in ('P','M')
      	Group By ARTL.ARCo, Name, TaxCode, ARTL.ARTrans, ARTL.Mth
      
    
      insert into #Multilevel
    	(ARCo, ARTrans, ARLine, Mth,TransDate, Customer, Invoice, CheckNo, 
             Description, GLAcct,DiscOffered,TotalAmount,BaseTaxCode, Name)
      
    	Select ARTL.ARCo, ARTL.ARTrans, ARTL.ARLine, ARTL.Mth,ARTH.TransDate, ARTH.Customer, ARTH.Invoice, ARTH.CheckNo, 
            ARTL.Description, ARTL.GLAcct,ARTL.DiscOffered,ARTL.Amount,ARTL.TaxCode, HQCO.Name
    	from ARTL with (nolock) 
           Inner Join ARTH  with (nolock) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
		   Inner Join HQCO with (nolock) on HQCO.HQCo=ARTL.ARCo
    	where  @NoTaxLines ='Y' and ARTL.ARCo=@ARCo and ARTL.TaxCode is null
   		and ARTL.Mth between @BeginMth and @EndMth  
   		and ARTH.ARCo=@ARCo and ARTH.Mth between @BeginMth and @EndMth 
   		and ARTH.ARTransType Not in ('P','M')
     
    
    Select * from #Multilevel
      
      /* created 7/15/97 Tracy -- select the results -- 
      
        SELECT HQCO.Name,ARTL.ARCo, ARTL.ARTrans, ARTL.ARLine, ARTL.Mth,
              ARTH.TransDate, ARTH.Customer,
      	ARTH.Invoice, ARTH.CheckNo, ARTL.Description,
      	BaseTaxCode=base.TaxCode,
      	BaseTaxDesc=base.Description,
      	MultiLevel=base.MultiLevel,
      	LocalTaxCode=case base.MultiLevel when 'Y' then #BaseRate.LocalTaxCode  else #BaseRate.TaxCode end,
      	LocalTaxDesc=case base.MultiLevel when 'Y' then #BaseRate.Description  end,
      	GLAcct=case base.MultiLevel when 'Y' then #BaseRate.GLAcct else base.GLAcct end,
      	ARTL.TaxBasis,
      	ARTL.TaxAmount,
      	
      	TaxRate=case  base.MultiLevel when 'Y'
      	        then
      	
      	TaxRate= case when ARTH.TransDate < isnull(#BaseRate.EffectiveDate,'12/31/2070') then (#BaseRate.OldBaseRate)
      	      	       when ARTH.TransDate >= isnull(#BaseRate.EffectiveDate,'12/31/2070') then (#BaseRate.NewBaseRate)
      	    	 end,
      	 BeginTaxCode=@BeginTaxCode, EndTaxCode=@EndTaxCode, BeginMth=@BeginMth, EndMth=@EndMth
      FROM ARTL
      
      Inner Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
      Inner Join HQCO on ARTL.ARCo=HQCO.HQCo
      Inner Join HQTX base on base.TaxGroup=ARTL.TaxGroup and base.TaxCode=ARTL.TaxCode
      Inner Join #BaseRate on #BaseRate.TaxGroup=ARTL.TaxGroup and #BaseRate.TaxCode=ARTL.TaxCode
      
      Full outer Join HQTL on HQTL.TaxGroup = ARTL.TaxGroup and HQTL.TaxCode = ARTL.TaxCode
      Full outer Join HQTX local on local.TaxGroup = HQTL.TaxGroup and local.TaxCode = HQTL.TaxLink
      
      
        WHERE ARTL.ARCo=@ARCo and ARTL.TaxCode>=@BeginTaxCode and ARTL.TaxCode<=@EndTaxCode
        and ARTL.Mth>=@BeginMth and ARTL.Mth<=@EndMth
      
      
      
      
      order by ARTL.ARCo, ARTL.ARTrans,ARTL.ARLine,ARTL.Mth, ARTH.TransDate,ARTH.Customer,
      	ARTH.Invoice, ARTH.CheckNo, ARTL.Description, ARTL.TaxCode, HQTL.TaxCode,
      	ARTL.TaxBasis,ARTL.TaxAmount,HQTL.TaxLink
      */

GO
GRANT EXECUTE ON  [dbo].[brptARSalesTax] TO [public]
GO
