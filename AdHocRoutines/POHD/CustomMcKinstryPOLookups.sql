--select * from DDLHShared where FromClause like '%POHD%'
use Viewpoint
go


/*
--Make backups of tables to be touched.

select * into vDDLH_20141116_LWO from vDDLH
select * into vDDLHc_20141116_LWO from vDDLHc
select * into vDDLD_20141116_LWO from vDDLD
select * into vDDLDc_20141116_LWO from vDDLDc
select * into vDDFLc_20141116_LWO from vDDFLc
select * into vRPPLc_20141116_LWO from vRPPLc

*/

print @@SERVERNAME + '.' + db_name()
go


if exists ( select 1 from sysobjects where type='P' and name='mspCreateMckLookupCopy')
begin
	print 'DROP PROCEDURE mspCreateMckLookupCopy'
	DROP PROCEDURE mspCreateMckLookupCopy
end
go

print 'CREATE PROCEDURE mspCreateMckLookupCopy'
print ''
go


create procedure mspCreateMckLookupCopy
(
	@LookupRef	varchar(30)
,	@DoSQL		int = 0
)
as

set nocount on

/*
2014.11.15 - LWO - CREATED

IMPLEMENTATION PLAN

1. Create McK Copies of all POHD Lookups by copying entries from DDLH & DDLD into vDDLHc & vDDLDc with an 'm' prefix
2. Add the udMCKPONumber field to copied custom lookups (insert row into vDDLDc)
3. Find all occurrance of original Lookups in DD tables and update them to use new 'ud%' versions.

2014.11.19 - LWO - Needed to adjust the order of lookup columns so that the PO Request # is the first column.  The first column in
the lookup needs to be the primary key (in this case PO) so the source record has the coorect foreign key value.
*/

declare lucur cursor for
select
	Lookup	
,	Title	
,	FromClause	
,	WhereClause	
,	JoinClause	
,	OrderByColumn	
,	Memo	
,	GroupByClause	
,	Version
from
	DDLHShared
where
	Lookup=@LookupRef
order by 
	Lookup
for read only

declare @rcnt			int
DECLARE @Lookup			varchar(30)
DECLARE @Title			varchar(30)
DECLARE @FromClause		varchar(256)
DECLARE @WhereClause	varchar(512)
DECLARE @JoinClause		varchar(512)
DECLARE @OrderByColumn	tinyint
DECLARE @Memo			varchar(1024)
DECLARE @GroupByClause	varchar(256)	
DECLARE @Version		tinyint

DECLARE @Seq			smallint
DECLARE @ColumnName		varchar(256)
DECLARE @ColumnHeading	varchar(30)
DECLARE @Hidden			bYN
DECLARE @Datatype		varchar(30)
DECLARE @InputType		tinyint
DECLARE @InputLength	smallint
DECLARE @InputMask		varchar(30)
DECLARE @Prec			tinyint

DECLARE @NewLookup		varchar(30)
declare @newSeq			int
set @rcnt=0

open lucur
fetch lucur into
	@Lookup			--varchar(30)
,	@Title			--varchar(30)
,	@FromClause		--varchar(256)
,	@WhereClause	--varchar(512)
,	@JoinClause		--varchar(512)
,	@OrderByColumn	--tinyint
,	@Memo			--varchar(1024)
,	@GroupByClause	--varchar(256)	
,	@Version		--tinyint

while @@FETCH_STATUS=0
begin

	set @rcnt=@rcnt+1
	print REPLICATE('-',100)
	print
		cast(@rcnt as char(8))
	+	cast('ORIGINAL' as char(10))
	+	cast(@Lookup as char(32))
	+	cast(@Title as char(32))

	if not exists ( select 1 from DDLHShared where Lookup='ud' + replace(@Lookup,'ud','') )
	begin

		select @NewLookup = 'ud' + @Lookup
		print 	
			cast('' as char(8))
		+	cast('ADD' as char(10))
		+	cast(@NewLookup as char(32))
		+	cast('McK:' + @Title  as char(32))
		+	cast('(' + @Lookup + ')'  as char(32))
	
		-- DO INSERT OF NEW LOOKUP HEADER HERE
		-- COPY ALL FROM ORIGINAL CHANGING NAME & DESC

		if @DoSQL=1
		begin
			insert vDDLHc ( Lookup, Title, FromClause, WhereClause, JoinClause, OrderByColumn, Memo, GroupByClause, Version)
			select
				@NewLookup			--varchar(30)
			,	'McK:' + @Title			--varchar(30)
			,	@FromClause		--varchar(256)
			,	@WhereClause	--varchar(512)
			,	@JoinClause		--varchar(512)
			,	@OrderByColumn	--tinyint
			,	@Memo + '; Copied from ' + 	@Lookup		--varchar(1024)
			,	@GroupByClause	--varchar(256)	
			,	@Version		--tinyint
		end

		print REPLICATE('-',100)

		select @newSeq = 0

		declare ludetcur cursor for
		select 
			Seq
		,	ColumnName
		,	ColumnHeading
		,	Hidden
		,	Datatype
		,	InputType
		,	InputLength
		,	InputMask
		,	Prec
		from
			DDLDShared
		where 
			Lookup=@Lookup
		order by 
			Seq
		for read only

		open ludetcur
		fetch ludetcur into
			@Seq
		,	@ColumnName
		,	@ColumnHeading
		,	@Hidden
		,	@Datatype
		,	@InputType
		,	@InputLength
		,	@InputMask
		,	@Prec



		while @@FETCH_STATUS=0
		begin

			select @newSeq=@newSeq+10

			print 	
				cast('' as char(18))
			+	cast('ORIGINAL' as char(10))
			+	cast(@newSeq as char(8))
			+	cast(@ColumnHeading  as char(32))
			+	cast(@ColumnName  as char(200))
			

			-- INSERT LOOKUP DETAILS TO NEW LOOKUP FROM ORIGINAL
			-- COPY ALL FROM ORIGINAL CHANGING COLUMN HEAD & SEQ ( set to increments of 10 )


			if @DoSQL=1
			begin
				insert vDDLDc ( Lookup, Seq, ColumnName, ColumnHeading, Hidden, Datatype, InputType, InputLength, InputMask, Prec )
				select 
					@NewLookup
				,	@newSeq
				,	@ColumnName
				,	case
						when @ColumnName='PO' then 'PO Request#'
						else @ColumnHeading
					end
				,	@Hidden
				,	@Datatype
				,	@InputType
				,	@InputLength
				,	@InputMask
				,	@Prec
			end

			fetch ludetcur into
				@Seq
			,	@ColumnName
			,	@ColumnHeading
			,	@Hidden
			,	@Datatype
			,	@InputType
			,	@InputLength
			,	@InputMask
			,	@Prec

		end
	
		close ludetcur
		deallocate ludetcur

		--- BEGIN LOOP FOR EACH COLUMN NEEDING TO BE ADDED TO CUSTOM LOOKUP

		if not exists ( select 1 from DDLDShared where ColumnName='udMCKPONumber' and Lookup=@Lookup )
		begin

			print
				cast('' as char(18))
			+	cast('ADD' as char(10))
			+	cast(5 as char(8))
			+	cast('MCK PO#'  as char(32))
			+	cast('udMCKPONumber'  as char(200))

			-- INSERT ADDITIONAL CUSTOM LOOKUP DETAIL RECORD
			if @DoSQL=1
			begin
				insert vDDLDc ( Lookup, Seq, ColumnName, ColumnHeading, Hidden, Datatype, InputType, InputLength, InputMask, Prec )
				select
					@NewLookup
				,	15
				,	'udMCKPONumber'
				,	'McK PO#'
				,	'N'
				,	null
				,	0
				,	30
				,	null
				,	null

				update vDDLHc set OrderByColumn=15 where Lookup=@NewLookup
			END
			
		end
		else
		begin
		
		PRINT
			cast('' as char(18))
		+	cast('EXISTS' as char(10))
		+	cast('' as char(8))
		+	cast('MCK PO#'  as char(32))
		+	cast('udMCKPONumber'  as char(200))

		end

		--- END LOOP FOR EACH COLUMN NEEDING TO BE ADDED TO CUSTOM LOOKUP

	end
	else
	begin
		
		select @NewLookup = 'ud' + replace(@Lookup,'ud','')
		
		print 	
			cast('' as char(8))
		+	cast('EXISTS' as char(10))
		+	cast(@NewLookup as char(32))
		+	cast('McK:' + @Title  as char(32))

		print REPLICATE('-',100)

		--- BEGIN LOOP FOR EACH COLUMN NEEDING TO BE ADDED TO CUSTOM LOOKUP

		if not exists ( select 1 from DDLDShared where ColumnName='udMCKPONumber' and Lookup=@NewLookup )
		begin

			--Get Max Sequence 
			select @Seq=max(Seq) from DDLDShared where Lookup=@Lookup

			print
				cast('' as char(18))
			+	cast('ADD' as char(10))
			+	cast(@Seq+1 as char(8)) 
			+	cast('MCK PO#'  as char(32))
			+	cast('udMCKPONumber'  as char(200))

			-- INSERT ADDITIONAL CUSTOM LOOKUP DETAIL RECORD
			if @DoSQL=1
			begin
				insert vDDLDc ( Lookup, Seq, ColumnName, ColumnHeading, Hidden, Datatype, InputType, InputLength, InputMask, Prec )
				select
					@NewLookup
				,	@Seq+1
				,	'udMCKPONumber'
				,	'McK PO#'
				,	'N'
				,	null
				,	0
				,	30
				,	null
				,	null

				update vDDLHc set OrderByColumn=@Seq+1 where Lookup=@NewLookup
			END
		end
		else
		begin
		
		PRINT
			cast('' as char(18))
		+	cast('EXISTS' as char(10))
		+	cast('' as char(8))
		+	cast('MCK PO#'  as char(32))
		+	cast('udMCKPONumber'  as char(200))

		end
	end	
	--- END LOOP FOR EACH COLUMN NEEDING TO BE ADDED TO CUSTOM LOOKUP

	/*
		In DDFL tables, we need to insert row into vDDFLc.  If Form, Lookup and Seqence are the same as in DDFL, it serves as an override of the default.
		Records in DDFL only are standard, records that match in both DDFL an DDFLc are treated as an override, and once in DDFLc only are custom,
	*/
	print 	
		cast('' as char(18))
	+	'DISABLE ORIGINAL LOOKUP ON ALL FORM FIELDS AND REPORT PARAMETER FIELDS and ADD/ENABLE NEW CUSTOM VERSION'

	if @DoSQL=1
	begin

		-- FORM FIELD LOOKUPS
		--Override Original Value and Disable
		insert vDDFLc (Form, Seq, Lookup, LookupParams, Active, LoadSeq)
		select Form, Seq, Lookup, LookupParams, 'N', LoadSeq
		from vDDFL where Lookup=@Lookup

		print
			cast('' as char(18))
		+	cast(@@rowcount as varchar(10)) + ' Form Field Lookups Disabled'

		--Replace with new version, enabled, using the same settings as the original.
		insert vDDFLc (Form, Seq, Lookup, LookupParams, Active, LoadSeq)
		select Form, Seq, @NewLookup, LookupParams, 'Y', LoadSeq
		from vDDFL where Lookup=@Lookup

		print
			cast('' as char(18))
		+	cast(@@rowcount as varchar(10)) + ' Form Field Lookups Replaced with new Lookup'

		-- REPORT PARAMETER FIELD LOOKUPS
		--Override Original Value and Disable
		insert vRPPLc (ReportID, ParameterName, Lookup, LookupParams, LoadSeq, Active)
		select ReportID, ParameterName, Lookup, LookupParams, LoadSeq, 'N'
		from vRPPL where Lookup=@Lookup

		print
			cast('' as char(18))
		+	cast(@@rowcount as varchar(10)) + ' Report Parameter Field Lookups Disabled'

		--Replace with new version, enabled, using the same settings as the original.
		insert vRPPLc (ReportID, ParameterName, Lookup, LookupParams, LoadSeq, Active)
		select ReportID, ParameterName, @NewLookup, LookupParams, LoadSeq, 'Y'
		from vRPPL where Lookup=@Lookup

		print
			cast('' as char(18))
		+	cast(@@rowcount as varchar(10)) + ' Report Parameter Field Lookups Replaced with new Lookup'

	end

	print ''

	fetch lucur into
		@Lookup			--varchar(30)
	,	@Title			--varchar(30)
	,	@FromClause		--varchar(256)
	,	@WhereClause	--varchar(512)
	,	@JoinClause		--varchar(512)
	,	@OrderByColumn	--tinyint
	,	@Memo			--varchar(1024)
	,	@GroupByClause	--varchar(256)	
	,	@Version		--tinyint

end

close lucur
deallocate lucur

select 'Form' as Element, Form as ElementName from DDFLShared where Lookup=@NewLookup
union
select 'Report' as Element, r.Title as ElementName from RPPLShared rl join RPRT r on rl.ReportID=r.ReportID where rl.Lookup=@NewLookup
order by 1,2

go


/* ALREADY COMPLETED IN STAGING AND PRODUCTION */
--exec mspCreateMckLookupCopy @LookupRef='POHDByVendor'				,@DoSQL=1      --Purchase Order Header
--exec mspCreateMckLookupCopy @LookupRef='POHDByVendorAll'			,@DoSQL=1       --All Vendor Purchase Orders


/* TO BE COMPLETED  */
--exec mspCreateMckLookupCopy @LookupRef='POHD'						,@DoSQL=0      --Purchase Order Header
--exec mspCreateMckLookupCopy @LookupRef='POHD'						,@DoSQL=0       --All Purchase Orders
--exec mspCreateMckLookupCopy @LookupRef='POHD1'					,@DoSQL=0      	--Purchase Order Header
--exec mspCreateMckLookupCopy @LookupRef='udPOHDmck'				,@DoSQL=0 		--All Purchase Orders with MCK#

--exec mspCreateMckLookupCopy @LookupRef='POHDByJob'				,@DoSQL=0       --Purchase Orders By Job
--exec mspCreateMckLookupCopy @LookupRef='POHDByJobForPM'			,@DoSQL=0       --Purchase Orders By Project
--exec mspCreateMckLookupCopy @LookupRef='POHDByJobForPMStatusOpen'	,@DoSQL=0		--Approved PO's By Project
--exec mspCreateMckLookupCopy @LookupRef='POHDByStatus'				,@DoSQL=0       --Open or Completed PO's
--exec mspCreateMckLookupCopy @LookupRef='POHDByVendor'				,@DoSQL=0       --Purchase Order Header
--exec mspCreateMckLookupCopy @LookupRef='POHDByVendorAll'			,@DoSQL=0       --All Vendor Purchase Orders
--exec mspCreateMckLookupCopy @LookupRef='POHDByVendorForPM'		,@DoSQL=0       --PO Vendors By Project
--exec mspCreateMckLookupCopy @LookupRef='POHDNoPending'			,@DoSQL=0       --Purchase Orders
--exec mspCreateMckLookupCopy @LookupRef='POHDStatusOpen'			,@DoSQL=0       --Open Purchase Orders Only
--exec mspCreateMckLookupCopy @LookupRef='POHDWithStatus'			,@DoSQL=0       --Purchase Orders
--exec mspCreateMckLookupCopy @LookupRef='POOpen'					,@DoSQL=0       --Open Purchase Orders
--exec mspCreateMckLookupCopy @LookupRef='POOpenPurchOrd'			,@DoSQL=0       --Open Purchase Orders
--exec mspCreateMckLookupCopy @LookupRef='POReceived'				,@DoSQL=0       --Purchase Order Receiving Items
--exec mspCreateMckLookupCopy @LookupRef='POReceivedOpen'			,@DoSQL=0       --Open PO's Only


/*
-- Helper queries to get target lookups and their associated Form/Report fields

--select * from DDLHShared where FromClause like '%POHD%'

--select 'Form' as Element, f.Title + ' (' + fl.Form + ')' as ElementName,fl.Lookup from DDFLShared fl join DDFHShared f on f.Form=fl.Form where fl.Lookup in (select distinct Lookup from DDLHShared where FromClause like '%POHD%')
--union
--select 'Report' as Element, r.Title as ElementName,rl.Lookup from RPPLShared rl join RPRT r on rl.ReportID=r.ReportID where rl.Lookup in (select distinct Lookup from DDLHShared where FromClause like '%POHD%')
*/


