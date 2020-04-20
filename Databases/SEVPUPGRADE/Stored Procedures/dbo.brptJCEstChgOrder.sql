SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Drop proc brptJCEstChgOrder  
    CREATE             proc [dbo].[brptJCEstChgOrder]  
        (@JCCo bCompany, @BeginContract bContract ='', @EndContract bContract= 'zzzzzzzzz',  
        @EndMonth bMonth)  
     
   /******  
    Created by DH  
    Stored Procedure used by the JC Contract Profit with Change Orders Report.  Procedure combines information from job cost, pending change orders, approved   
    change orders, and pending change order addons  
     
    Mod 4/16/2002 by DH - Issue 14975.  Altered procedure to insert approved change orders and addons, orignally setup as pending, after the End Month.    
                                        Also remmed out PendCOCosts cursor and replaced with insert statement - should help performance.  
    Mod 11/5/04 CR added NoLock #25915  
     
    Mod 3/31/05 CR added JCIP.ProjDollars  #27209  
    Mod 6/29/05 CR Added ProjMth field #29159  
   ********/  
      
      
     
    as  
    declare @Contract bContract, @Item bContractItem, @Job bJob, @PhaseGroup tinyint, @Phase bPhase, @PhaseDesc varchar(30), @CostType tinyint, @CTAbbrev char(5),   
            @PCOEstCost decimal(12,2)  
        create table #JCEstWithChgOrder  
               (JCCo           tinyint        NULL,  
                Contract       char(10)       NULL,  
                Item           char(16)       NULL,  
                Job         varchar(10)     NULL,     
                Phase          varchar(20)    NULL,  
                PhaseDesc      varchar(60)    NULL,  
                CostType       tinyint        NULL,  
                CostTypeAbrev  char(10)        NULL,  
         OrigEstCost    decimal(12,2)  NULL,  
                CurEstCost     decimal(12,2)  NULL,  
                ActualCost     decimal(12,2)  NULL,  
                ProjectedCost  decimal(12,2)  NULL,  
                PCOEstCost     decimal(12,2)  NULL,  
                ProjDollars    decimal(12,2)  Null,  
                BilledAmt      decimal(12,2)  Null,   
                ContractAmt    decimal(12,2)  Null,  
         ProjRevenue    decimal(12,2)  Null,  
                OrigContAmt    decimal(12,2)  Null)  
                 
     
                         
      
       Create table #PMChgOrdersWithAddons  
    (PMCo tinyint NULL,  
     Project varchar (10) NULL,  
     PCOType varchar (10) NULL,  
     PCO varchar (10) NULL,  
     PCOItem varchar (10) NULL,  
     ACO varchar  (10) NULL,  
     ACOItem varchar(10) NULL,  
     PhaseGroup tinyint NULL,  
     Phase varchar(20) NULL,  
     CostType tinyint NULL,  
            EstCost numeric (16,2) NULL)  
            --,InterfacedDate smalldatetime NULL)  
     
     
        insert into #JCEstWithChgOrder   
        (JCCo, Contract, Item, Job, Phase, PhaseDesc, CostType, CostTypeAbrev, OrigEstCost, CurEstCost, ActualCost,   
         ProjectedCost)  
      
        Select c.JCCo, c.Contract, c.Item, j.Job, j.Phase, j.Description, p.CostType,  t.Abbreviation,   
               sum(p.OrigEstCost), sum(p.CurrEstCost), sum(p.ActualCost), sum(p.ProjCost)  
                
                       
               From JCCI c with (NOLOCK)  
               Join JCJP j with (NOLOCK) on j.JCCo=c.JCCo and j.Contract=c.Contract and j.Item=c.Item  
               Join JCCP p with (NOLOCK) on p.JCCo=j.JCCo and p.Job=j.Job and p.PhaseGroup=j.PhaseGroup  
                           and p.Phase=j.Phase   
               Join JCCT t with (NOLOCK) on t.PhaseGroup=p.PhaseGroup and t.CostType=p.CostType  
                 
          
               Where c.JCCo=@JCCo and c.Contract>=@BeginContract and c.Contract<=@EndContract and  
                     p.Mth<=@EndMonth   
               Group By c.JCCo, c.Contract, c.Item, j.Job, j.Phase, j.Description, p.CostType, t.Abbreviation  
                           
     
   --Insert Contract Item Revenue info  
     insert into #JCEstWithChgOrder   
      (JCCo, Contract, Item, ProjDollars, BilledAmt, ContractAmt, ProjRevenue,OrigContAmt)  
     
       Select p.JCCo, p.Contract, p.Item, sum(p.ProjDollars), sum(p.BilledAmt), sum(p.ContractAmt),  
   case when sum(p.ProjDollars) <> 0 then sum(p.ProjDollars) else sum(p.ContractAmt) end,  
   sum(p.OrigContractAmt)  
     
   from JCIP p  
     
   Where p.JCCo=@JCCo and p.Contract>=@BeginContract and p.Contract<=@EndContract and  
                     p.Mth<=@EndMonth   
     
   Group by p.JCCo, p.Contract, p.Item   
     
     
   --Insert Pending Change Order addons for non-interfaced pending change orders   
     
         insert into #PMChgOrdersWithAddons   
                           
           
    select a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, ACO=NULL, ACOItem=NULL, p.PhaseGroup, p.Phase, CostType, EstCost=AddOnAmount   
                --InterfacedDate=(select max(InterfacedDate) From PMOL Where PMCo=a.PMCo and Project=a.Project and PCOType=a.PCOType and PCO=a.PCO and PCOItem=a.PCOItem)  
                From PMOA a with (NOLOCK)  
    Join (Select distinct l.PMCo, l.Project, l.PCOType, l.PCO, l.PCOItem From PMOL l Where l.InterfacedDate is null) as OL  
                on OL.PMCo=a.PMCo and OL.Project=a.Project and OL.PCOType=a.PCOType and OL.PCO=a.PCO  
            and OL.PCOItem=a.PCOItem  
    Join PMPA p with (NOLOCK) on p.PMCo=a.PMCo and p.Project=a.Project and p.AddOn=a.AddOn  
    Join JCJP j with (NOLOCK) on j.JCCo=p.PMCo and j.Job=p.Project and j.PhaseGroup=p.PhaseGroup and j.Phase=p.Phase  
    Where a.PMCo=@JCCo and j.Contract>=@BeginContract and j.Contract<=@EndContract  
     
   --Insert Pending Change Order costs for non-interfaced pending change orders  
     
          insert into #PMChgOrdersWithAddons   
    select PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, l.PhaseGroup, l.Phase, CostType, EstCost/*, InterfacedDate */ From PMOL l  
                Join JCJP j with (NOLOCK) on j.JCCo=l.PMCo and j.Job=l.Project and j.PhaseGroup=l.PhaseGroup and j.Phase=l.Phase  
    Where l.PMCo=@JCCo and  j.Contract>=@BeginContract and j.Contract<=@EndContract and l.InterfacedDate is null  
     
   --Insert Pending Change Order addons for approved change orders, which originated from pending, where the approved month is greater than the Through Month  
   insert into #PMChgOrdersWithAddons  
   select a.PMCo, a.Project, a.PCOType, a.PCO, a.PCOItem, ACO=NULL, ACOItem=NULL, p.PhaseGroup, p.Phase, CostType, EstCost=AddOnAmount   
                From PMOA a with (NOLOCK)  
    Join (Select distinct i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem From PMOI i   
            Join JCOI with (NOLOCK) on JCOI.JCCo=i.PMCo and JCOI.Job=i.Project and JCOI.ACO=i.ACO and JCOI.ACOItem=i.ACOItem  
            Where JCOI.ApprovedMonth > @EndMonth) as OI  
                 on OI.PMCo=a.PMCo and OI.Project=a.Project and OI.PCOType=a.PCOType and OI.PCO=a.PCO  
            and OI.PCOItem=a.PCOItem  
    Join PMPA p with (NOLOCK) on p.PMCo=a.PMCo and p.Project=a.Project and p.AddOn=a.AddOn  
    Join JCJP j with (NOLOCK) on j.JCCo=p.PMCo and j.Job=p.Project and j.PhaseGroup=p.PhaseGroup and j.Phase=p.Phase  
    Where a.PMCo=@JCCo and j.Contract>=@BeginContract and j.Contract<=@EndContract  
     
     
   --insert Pending Change Order costs for approved change orders, which originated from pending, where the approved month is greater than the Through Month  
   insert into #PMChgOrdersWithAddons  
    select PMOI.PMCo, PMOI.Project, PMOI.PCOType, PMOI.PCO, PMOI.PCOItem, PMOI.ACO, PMOI.ACOItem, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, PMOL.EstCost From PMOI  
       Join PMOL with (NOLOCK) on PMOL.PMCo=PMOI.PMCo and PMOL.Project=PMOI.Project and isnull(PMOL.PCOType,'')=isnull(PMOI.PCOType,'')  
            and isnull(PMOL.PCO,'')=isnull(PMOI.PCO,'') and isnull(PMOL.PCOItem,'')=isnull(PMOI.PCOItem,'') and PMOL.ACO=PMOI.ACO  
            and PMOL.ACOItem=PMOI.ACOItem  
       Join JCOI with (NOLOCK) on JCOI.JCCo=PMOI.PMCo and JCOI.Job=PMOI.Project and JCOI.ACO=PMOI.ACO and JCOI.ACOItem=PMOI.ACOItem  
    Where PMOI.PMCo=@JCCo and PMOI.Contract>=@BeginContract and PMOI.Contract<=@EndContract and JCOI.ApprovedMonth > @EndMonth  
     
    /*     declare bcPendCOCosts cursor for select c.Contract, c.Item, p.Project, p.PhaseGroup, p.Phase, j.Description, p.CostType, t.Abbreviation,  
                 sum(p.EstCost)  
                 From JCCI c   
                 Join JCJP j on j.JCCo=c.JCCo and j.Contract=c.Contract and j.Item=c.Item  
                 Join #PMChgOrdersWithAddons p on p.PMCo=j.JCCo and p.Project=j.Job and p.PhaseGroup=j.PhaseGroup and p.Phase=j.Phase  
                 Left Outer Join PMOI i on i.PMCo=p.PMCo and i.Project=p.Project and isnull(i.PCOType,'')=isnull(p.PCOType,'') and  
                   isnull(i.PCO,'')=isnull(p.PCO,'') and isnull(i.PCOItem,'')=isnull(p.PCOItem,'') and  
                   isnull(i.ACO,'')=isnull(p.ACO,'') and isnull(i.ACOItem,'')=isnull(p.ACOItem,'')  
                 Left Outer Join PMSC s on s.Status=i.Status  
                 Join JCCT t on t.PhaseGroup=p.PhaseGroup and t.CostType=p.CostType  
                 Where c.JCCo=@JCCo and c.Contract>=@BeginContract and c.Contract<=@EndContract  
                             and (s.IncludeInProj='Y' or s.IncludeInProj Is Null) --and p.InterfacedDate Is Null, Mod 4/16/02 by DH, Issue 14975  
                 Group By c.Contract, c.Item, p.Project, p.PhaseGroup, p.Phase, j.Description, p.CostType, t.Abbreviation  
     
      
                   
         open bcPendCOCosts  
           
         next_PCO:  
               
                 fetch next from bcPendCOCosts into @Contract, @Item, @Job, @PhaseGroup, @Phase, @PhaseDesc, @CostType, @CTAbbrev, @PCOEstCost  
                 if @@fetch_status=-1 goto end_PCO   
                 if @@fetch_status<>0 goto next_PCO                  
                 Update #JCEstWithChgOrder Set PCOEstCost=@PCOEstCost Where JCCo=@JCCo and Contract=@Contract  
                        and Item=@Item and Phase=@Phase and CostType=@CostType  
                   
                 if @@rowcount=0   
                     insert #JCEstWithChgOrder (JCCo, Contract, Item, Job, Phase, PhaseDesc, CostType, CostTypeAbrev, PCOEstCost)  
                     values (@JCCo, @Contract, @Item, @Job, @Phase, @PhaseDesc, @CostType, @CTAbbrev, @PCOEstCost)   
            
             goto next_PCO  
      
        end_PCO:  
             close bcPendCOCosts  
             deallocate bcPendCOCosts      */  
     
     
   insert into #JCEstWithChgOrder  
   (JCCo, Contract, Item, Job, Phase, PhaseDesc, CostType, CostTypeAbrev, PCOEstCost)  
   select p.PMCo, c.Contract, c.Item, p.Project, p.Phase, j.Description, p.CostType, t.Abbreviation,  
                 sum(p.EstCost) 
                 From JCCI c with (NOLOCK)  
                 Join JCJP j with (NOLOCK) on j.JCCo=c.JCCo and j.Contract=c.Contract and j.Item=c.Item  
                 Join #PMChgOrdersWithAddons p with (NOLOCK) on p.PMCo=j.JCCo and p.Project=j.Job and p.PhaseGroup=j.PhaseGroup and p.Phase=j.Phase  
                 Left Outer Join PMOI i with (NOLOCK) on i.PMCo=p.PMCo and i.Project=p.Project and isnull(i.PCOType,'')=isnull(p.PCOType,'') and  
                   isnull(i.PCO,'')=isnull(p.PCO,'') and isnull(i.PCOItem,'')=isnull(p.PCOItem,'') and  
                   isnull(i.ACO,'')=isnull(p.ACO,'') and isnull(i.ACOItem,'')=isnull(p.ACOItem,'')  
                 Left Outer Join PMSC s with (NOLOCK) on s.Status=i.Status  
                 Join JCCT t with (NOLOCK) on t.PhaseGroup=p.PhaseGroup and t.CostType=p.CostType  
                 Where c.JCCo=@JCCo and c.Contract>=@BeginContract and c.Contract<=@EndContract  
                             and (s.IncludeInProj in ('Y', 'C') or s.IncludeInProj Is Null) --and p.InterfacedDate Is Null, Mod 4/16/02 by DH, Issue 14975  
                 Group By p.PMCo, c.Contract, c.Item, p.Project, p.PhaseGroup, p.Phase, j.Description, p.CostType, t.Abbreviation   
     
     
    Select   JCCM.JCCo, CoName=HQCO.Name, JCCM.Contract, JCCM.Description, Item,  #JCEstWithChgOrder.Job, #JCEstWithChgOrder.OrigContAmt,  
                --ContractAmt=(select sum(ContractAmt) From JCIP  Where JCCo=JCCM.JCCo and Contract=JCCM.Contract and Mth<=@EndMonth),   
         --BilledAmt=(select sum(BilledAmt) From JCIP  Where JCCo=JCCM.JCCo and Contract=JCCM.Contract and Mth<=@EndMonth),  
                --ProjDollars=(select sum(ProjDollars) from JCIP  where JCCo=JCCM.JCCo and Contract=JCCM.Contract and Mth<=@EndMonth),              
                #JCEstWithChgOrder.ContractAmt, #JCEstWithChgOrder.BilledAmt, #JCEstWithChgOrder.ProjDollars,#JCEstWithChgOrder.ProjRevenue,  
   #JCEstWithChgOrder.Phase, PhaseDesc, #JCEstWithChgOrder.CostType , CostTypeAbrev,OrigEstCost, CurEstCost, ActualCost, ProjectedCost,  
                PCOEstCost, JCCH.Plugged From #JCEstWithChgOrder  
                Join JCCM with (NOLOCK) on JCCM.JCCo=#JCEstWithChgOrder.JCCo and JCCM.Contract=#JCEstWithChgOrder.Contract  
                left Join JCCH with (NOLOCK) on #JCEstWithChgOrder.JCCo = JCCH.JCCo and  
        #JCEstWithChgOrder.Job = JCCH.Job and  
        #JCEstWithChgOrder.Phase = JCCH.Phase and  
        #JCEstWithChgOrder.CostType = JCCH.CostType   
                Join HQCO with (NOLOCK) on HQCO.HQCo=#JCEstWithChgOrder.JCCo  
GO
GRANT EXECUTE ON  [dbo].[brptJCEstChgOrder] TO [public]
GO
