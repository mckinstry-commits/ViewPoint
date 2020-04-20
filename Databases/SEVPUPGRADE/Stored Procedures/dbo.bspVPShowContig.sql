SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVPShowContig    Script Date: 09/14/2004 ******/
   CREATE   procedure [dbo].[bspVPShowContig]
   /************************************
   * Created By:	GF 09/14/2004
   * Modified By:
   *
   * Used to generate a list of Viewpoint tables and indexes that are in need of 
   * defragmentation or re-indexing.
   *
   * Input paramters:
   *
   ************************************/
   as
   set nocount on
   
   -- -- -- first thing is to check for temp table and drop if already exists.
   if object_id('tempdb.dbo.#VPShowContigOutput') is not null
   	drop table #VPShowContigOutput
   
   -- -- -- create temp table VPShowContigOutput
   Create table #VPShowContigOutput
   (
   	ObjectName				sysname,
   	ObjectId					int,
   	IndexName				sysname,
   	IndexId					tinyint,
   	[Level]					tinyint,
   	Pages					int,
   	[Rows]					bigint,
   	MinimumRecordSize		smallint,
   	MaximumRecordSize		smallint,
   	AverageRecordSize		smallint,
   	ForwardRecords			bigint,
   	Extents					int,
   	ExtentSwitches			numeric(10,2),
   	AverageFreeBytes		numeric(10,2),
   	AveragePageDensity		numeric(10,2),
   	ScanDensity				numeric(10,2),
   	BestCount				int,
   	ActualCount				int,
   	LogicalFragmentation		numeric(10,2),
   	ExtentFragmentation		numeric(10,2)
   )
   
   
   -- -- -- all tables, all indexes will be processed
   insert #VPShowContigOutput
   	EXEC('DBCC SHOWCONTIG WITH FAST, ALL_INDEXES, TABLERESULTS')
   
   -- -- -- select results
   select vp.*
   from #VPShowContigOutput as vp
   join sysobjects as so on vp.ObjectId = so.id
   where ObjectName like 'b%' --and vp.LogicalFragmentation > 20
   and (objectproperty(vp.ObjectId, 'IsUserTable') = 1 or objectproperty(vp.ObjectId, 'IsView') = 1)
   and so.status > 0
   and vp.IndexId between 1 and 250
   and vp.ObjectName not in ('dtproperties')
   
   
   -- -- --drop table #VPShowContigOutput

GO
GRANT EXECUTE ON  [dbo].[bspVPShowContig] TO [public]
GO
