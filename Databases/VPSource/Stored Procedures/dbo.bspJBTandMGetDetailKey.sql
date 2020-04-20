SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMGetDetailKey    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMGetDetailKey]
/***********************************************************
* CREATED BY	: kb 5/17/00
* MODIFIED BY	: GR 11/21/00 - changed datatype from bAPRef to bAPReference
* 		kb 4/17/01 - issue #12979
*    	kb 5/8/01 - issue #13341
*	 	kb 5/31/01 - issue #13621
*    	kb 10/16/1 - issue #14926
*     	kb 2/22/2 - issue #16250
*     	kb 5/29/2 - issue #17414
*		TJL 08/21/02 - Issue #17472, Return MSTicket value
*		TJL 10/16/02 - Issue #19022, ANSI NULL, problems.  Prevent adding NULL String Variables
*						together.
*		TJL 09/24/03 - Issue #22443, Correct Source 'MT' set @material = NULL code
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 04/08/04 - Issue #24194, Correct a problem with SeqSummaryOpt = 99
*		TJL 04/20/04 - Issue #24376, Add Source 'MS' using 'E' CTCategory
*		TJL 05/03/04 - Issue #23813, Add New PR Labor Summary Options 18,19 and PR Labor SortLevels 13,14
*		TJL 10/04/05 - Issue #29972, Remove JC Transaction specific values when SeqSummaryOpt set to 99
*		TJL 05/30/06 - Issue #121150 (5x #121136), Correct @Source = AP, SumOpt = 3, SortOpt = 4:  Add APRef to DetailKey
*		TJL 10/27/08 - Issue #129320, Add New PR Labor Summary Options 20 by Craft, Class, Factor, Shift
*		TJL 03/19/09 - Issue #120614, Add ability to include Rate value in summarization of PR Sources
*		GF  06/25/2010 - issue #135813 expanded SL to varchar(30)
*
*
* USED IN:
*
* USAGE:
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/

(@co bCompany, @jcmth bMonth, @jctrans bTrans, @source char(2) output,
@seqsortlevel tinyint output, @seqsummaryopt tinyint output,
@seqcategory varchar(10) output,
@prco bCompany output, @employee bEmployee output, @craft bCraft output,
@class bClass output, @earntype varchar(4) output, @factor bRate output,
@ctcategory char(1) output, @shift tinyint output, @apco bCompany output,
@vendorgroup bGroup output, @vendor bVendor output, @apref bAPReference output,
@inco bCompany output, @MSticket bTic output, @matlgroup bGroup output, @material bMatl output,
@loc bLoc output, @sl VARCHAR(30) output,
@slitem bItem output, @emgroup bGroup output, @equip bEquip output,
@revcode bRevCode output, @actualdate bDate output, @liabtype bLiabilityType output,
@jccddesc bDesc output, @emco bCompany output, @transct bJCCType output, @phasegroup bGroup output,
@po varchar(30) output, @poitem bItem output, @rate bUnitCost output, @detailkey varchar(500) output,
@postdate bDate output, @msg varchar(255) output)
as

/********** @seqcategory input is actually LaborCategory, EquipCategory or MaterialCategory! **********/

set nocount on

declare @rcode int, @spaces varchar(20), @vendorstring char(6),
   	@vendorgroupstring char(3), @employeestring char(6), @prcostring char(3),
   	@earntypestring char(4), @matlgroupstring char(3), @slitemstring char(5),
   	@poitemstring char(5), @emcostring char(3), @emgroupstring char(3),
   	@liabtypestring char(4), @transctstring char(3), @jctransstring char(12),
   	@shiftstring char(3), @summarizebyrate bYN
   
select @rcode = 0, @spaces = '                    ', @summarizebyrate = 'N'

if @vendorgroup is not null
exec bspHQFormatMultiPart @vendorgroup, '3RN', @vendorgroupstring output

if @vendor is not null
exec bspHQFormatMultiPart @vendor, '6RN', @vendorstring output

if @employee is not null
exec bspHQFormatMultiPart @employee, '6RN', @employeestring output

if @prco is not null
exec bspHQFormatMultiPart @prco, '3RN', @prcostring output

if @earntype is not null
exec bspHQFormatMultiPart @earntype, '4RN', @earntypestring output

if @matlgroup is not null
exec bspHQFormatMultiPart @matlgroup, '3RN', @matlgroupstring output

if @slitem is not null
exec bspHQFormatMultiPart @slitem, '3RN', @slitemstring output

if @poitem is not null
exec bspHQFormatMultiPart @poitem, '3RN', @poitemstring output

if @emco is not null
exec bspHQFormatMultiPart @emco, '3RN', @emcostring output

if @emgroup is not null
exec bspHQFormatMultiPart @emgroup, '3RN', @emgroupstring output

if @liabtype is not null
exec bspHQFormatMultiPart @liabtype, '4RN', @liabtypestring output

if @transct is not null
exec bspHQFormatMultiPart @transct, '3RN', @transctstring output

if @jctrans is not null
exec bspHQFormatMultiPart @jctrans, '12RN', @jctransstring output

if @shift is not null
exec bspHQFormatMultiPart @shift, '3RN', @shiftstring output

select @ctcategory = JBCostTypeCategory 
from JCCT j with (nolock)
join HQCO h with (nolock) on h.PhaseGroup = j.PhaseGroup 
where h.HQCo = @co and j.PhaseGroup = @phasegroup and CostType = @transct

/* Any value from Source PR greater than 100 indicates that user wishes to include rate in the summarization.
   Set a flag to indicate this and then remove 100 from the summary option value so processing can proceed
   as normal.  Because this is an "output" variable, we will add it back in later at end of procedure. */
if @seqsummaryopt > 100 and @source = 'PR' and @ctcategory <> 'E' 
	begin
	select @summarizebyrate = 'Y'
	select @seqsummaryopt = @seqsummaryopt - 100
	end

if @seqsummaryopt <> 1 select @jcmth = null, @jctrans = null

if @seqsummaryopt = 99 or @source not in ('EM','PR','SL','MT','AP','MS','IN')
   	begin
   	select @detailkey = case @source when 'PR' then 'PR line' 
   		when 'EM' then 'Equipment line' 
   		when 'SL' then 'APSLLine' 
   		when 'MT' then 'APMatlLine'
		when 'AP' then 'APExpLine' 
	else isnull(@source,'') end + isnull(@ctcategory,'')
		+ case when @seqcategory is null then convert(char(10), @spaces) else
     		convert(char(10),@seqcategory) end
  
  	if @seqsummaryopt = 99
  		begin
  		/* All transactions get grouped onto a single JBID line/Seq by Source and JBCostType Category.
  		   Individual transaction values have no meaning when grouped into single Line/Seq record. */
  		select @prco = null, @apco = null, @inco = null, @emco = null, @vendorgroup = null, @matlgroup = null, @emgroup = null,
  			@employee = null, @craft = null, @class = null, @earntype = null, @factor = null, @shift = null,
  			@vendor = null, @apref = null, @MSticket = null, @material = null, @loc = null, @sl = null, @slitem = null,
  			@equip = null, @revcode = null, @liabtype = null, @po = null, @poitem = null
  		end
   	end
else
   	begin
   	if @source = 'EM' or (@source = 'PR' and @ctcategory = 'E') or
   		(@source = 'MS' and @ctcategory = 'E')
       	begin
       	if @seqsummaryopt in (2,3,4,17,99) select @employee = null, @prco = null
        	if @seqsummaryopt in (2,3,4,16,99) select @craft  = null, @class = null
        	if @seqsummaryopt in (4,99) select @equip = null, @emco = null
         	if @seqsummaryopt in (3,99) select @revcode = null, @emgroup = null
   
       	select @detailkey = 'Equipment line' +
           	case @seqsortlevel
               	when 1 then case when @emco is null then convert(char(3),@spaces)
						else @emcostring end +
           			case when @equip is null then convert(char(10),@spaces)
               			else convert(char(10),@equip) end +
            		case when @emgroup is null then convert(char(3),@spaces)
                 		else @emgroupstring end + 
   					case when @revcode is null then convert(char(10),@spaces)
               			else convert(char(10),@revcode) end
				when 2 then case when @emgroup is null then convert(char(3),@spaces)
						else @emgroupstring end  + 
   					case when @revcode is null then convert(char(10),@spaces)
						else convert(char(10),@revcode) end + 
   					case when @emco is null then convert(char(3),@spaces)
						else @emcostring end +
                   	case when @equip is null then convert(char(10),@spaces)
						else convert(char(10),@equip) end
               	when 3 then case when @seqcategory is null then convert(char(10),@spaces)
						else convert(char(10),@seqcategory) end +
					case when @emco is null then convert(char(3),@spaces)
						else @emcostring end +
					case when @equip is null then convert(char(10),@spaces)
						else convert(char(10),@equip) end +
					case when @emgroup is null then convert(char(3),@spaces)
						else @emgroupstring end + 
   					case when @revcode is null then convert(char(10),@spaces)
						else convert(char(10),@revcode) end
				when 4 then case when @revcode is null then convert(char(10),@spaces)
						else convert(char(10),@revcode) end + 
   					case when @seqcategory is null then convert(char(10),@spaces)
						else convert(char(10),@seqcategory) end +
					case when @equip is null then convert(char(10),@spaces)
                        	else convert(char(10),@equip) end
				when 11 then case when @emco is null then convert(char(3),@spaces)
						else @emcostring end +
					case when @equip is null then convert(char(10),@spaces)
						else convert(char(10),@equip) end +
					case when @emgroup is null then convert(char(3),@spaces)
						else @emgroupstring end + 
   					case when @revcode is null then convert(char(10),@spaces)
						else convert(char(10),@revcode) end +
					case when @employee is null then convert(char(9),@spaces)
                        	else @prcostring + @employeestring end  +
                   	case when @craft is null then convert(char(10),@spaces)
						else convert(char(10),@craft) end +
      				case when @class is null then convert(char(10),@spaces)
   						else convert(char(10),@class) end
				when 12 then case when @emco is null then convert(char(3),@spaces)
						else @emcostring end +
					case when @equip is null then convert(char(10),@spaces)
     					else convert(char(10),@equip) end +
					case when @emgroup is null then convert(char(3),@spaces)
						else @emgroupstring end + 
   					case when @revcode is null then convert(char(10),@spaces)
						else convert(char(10),@revcode) end +
            		case when @craft is null then convert(char(10),@spaces)
						else convert(char(10),@craft) end + 
   					case when @class is null then convert(char(10),@spaces)
   						else convert(char(10),@class) end +
					case when @employee is null then convert(char(9),@spaces)
						else @prcostring + @employeestring end
       		end
		end

   	if @source = 'PR' and @ctcategory <> 'E'
       	begin
		if @seqsummaryopt in (3,6,8,10,12,14,16,99) select @craft = null
       	if @seqsummaryopt in (3,6,8,10,12,13,14,16,99) select @class = null
       	if @seqsummaryopt in (4,7,8,11,12,13,14,17,20,99) select @employee = null, @prco = null
       	if @seqsummaryopt in (2,3,4,9,10,11,12,13,14,15,16,17,19,20,99) select @earntype = null
		if @seqsummaryopt in (2,3,4,5,6,7,8,13,14,15,16,17,99) select @factor = null
		if @seqsummaryopt in (2,3,4,5,6,7,8,9,10,11,12,15,16,17,18,19,20,99) select @liabtype = null
   		if @seqsummaryopt in (2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,99) select @shift = null
		if @seqsummaryopt in (5,6,7,8,9,10,11,12,13,14,18,19,20,99) select @emco = null
		if @seqsummaryopt in (5,6,7,8,9,10,11,12,13,14,18,19,20,99) select @equip = null
		if @seqsummaryopt in (3,5,6,7,8,9,10,11,12,13,14,18,19,20,99) select @revcode = null, @emgroup = null
   
		select @detailkey = 'PR line' +
           	case @seqsortlevel
               	when 1 then case when @employee is null then convert(char(9),@spaces)
						else @prcostring + @employeestring end  +
              		case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end + 
					case when @earntype is null then convert(varchar(4),@spaces) 
   						else @earntypestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
				when 2 then case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end +
                	case when @earntype is null then convert(varchar(4),@spaces) 
   						else @earntypestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
               	when 3 then case when @seqcategory is null then convert(char(10),@spaces)
                    	else convert(char(10),@seqcategory) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end  +
                 	case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end + 
					case when @class is null then convert(char(10),@spaces)
   						else convert(char(10),@class) end +
					case when @earntype is null then convert(varchar(4),@spaces) 
   						else @earntypestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
               	when 4 then case when @seqcategory is null then convert(char(10),@spaces)
                    	else convert(char(10),@seqcategory) end +
                	case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                	case when @class is null then convert(char(10),@spaces)
            			else convert(char(10),@class) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end +
                	case when @earntype is null then convert(varchar(4),@spaces) 
   						else @earntypestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
               	when 5 then case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end  +
               		case when @craft is null then convert(char(10),@spaces)
     					else convert(char(10),@craft) end +
                	case when @class is null then convert(char(10),@spaces)
      					else convert(char(10),@class) end + 
					case when @factor is null then convert(char(10),@spaces)
                    	else convert(char(10),@factor) end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
				when 6 then case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end + 
					case when @factor is null then convert(char(10),@spaces)
                    	else convert(char(10),@factor) end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
               	when 7 then case when @seqcategory is null then convert(char(10),@spaces)
                    	else convert(char(10),@seqcategory) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end  +
                 	case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end + 
					case when @class is null then convert(char(10),@spaces)
						else convert(char(10),@class) end +
                 	case when @factor is null then convert(char(10),@spaces)
                    	else convert(char(10),@factor) end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
				when 8 then case when @seqcategory is null then convert(char(10),@spaces)
                    	else convert(char(10),@seqcategory) end +
                	case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end +
                 	case when @factor is null then convert(char(10),@spaces)
                    	else convert(char(10),@factor) end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
               	when 9 then case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end + 
					case when @class is null then convert(char(10),@spaces)
						else convert(char(10),@class) end +
                	case when @liabtype is null then convert(char(4),@spaces)
                    	else @liabtypestring end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
				when 10 then case when @seqcategory is null then convert(char(10),@spaces)
                    	else convert(char(10),@seqcategory) end +
                	case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end +
                  	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end +
                	case when @earntype is null then convert(varchar(4),@spaces) 
   						else @earntypestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
               	when 11 then @emcostring +
                 	case when @equip is null then convert(char(10),@spaces)
                    	else convert(char(10),@equip) end +
					case when @emgroup is null then convert(char(3),@spaces)
                    	else @emgroupstring end + 
					case when @revcode is null then convert(char(10),@spaces)
                    	else convert(char(10),@revcode) end +
                  	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end +
                 	case when @craft is null then convert(char(10),@spaces)
              			else convert(char(10),@craft) end +
					case when @class is null then convert(varchar(10),@spaces)
                       	else convert(char(10),@class) end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
				when 12 then @emcostring +
                 	case when @equip is null then convert(char(10),@spaces)
                    	else convert(char(10),@equip) end +
					case when @emgroup is null then convert(char(3),@spaces)
                    	else @emgroupstring end + 
					case when @revcode is null then convert(char(10),@spaces)
                    	else convert(char(10),@revcode) end +
					case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
				when 13 then case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end + 
					case when @factor is null then convert(char(10),@spaces)
                    	else convert(char(10),@factor) end +
                	case when @earntype is null then convert(varchar(4),@spaces) 
   						else @earntypestring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
				when 14 then case when @craft is null then convert(char(10),@spaces)
                    	else convert(char(10),@craft) end +
                 	case when @class is null then convert(char(10),@spaces)
                    	else convert(char(10),@class) end +
                 	case when @employee is null then convert(char(9),@spaces)
                    	else @prcostring + @employeestring end + 
					case when @factor is null then convert(char(10),@spaces)
                    	else convert(char(10),@factor) end +
                	case when @shift is null then convert(varchar(3),@spaces) 
   						else @shiftstring end +
					case when @summarizebyrate = 'Y' then
						case when @rate is null then convert(varchar(17),@spaces) 
							else convert(varchar, @rate) end else '' end
			end
		end

   	if @source = 'MT'
       	begin
  		if @seqsummaryopt in (6,9,99) select @vendor = null, @vendorgroup = null
     	if @seqsummaryopt in (5,6,8,10,12,13,14,99) select @apref = null
   		select @apref = @apref + @spaces
 		if @seqsummaryopt in (3,5,7,8,9,99) select @material = null, @matlgroup = null
     	if @seqsummaryopt in (2,3,4,5,6,99) select @po = null, @poitem = null
   
		select @detailkey = 'APMatlLine' +
           	case @seqsortlevel
               	when 1 then case when @material is null then convert(char(23),@spaces)
                		else @matlgroupstring + convert(char(20),@material) end +
                 	case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  +
                 	case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end
             	when 2 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  +
                  	case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  +
                 	case when @material is null then convert(char(23),@spaces)
                		else @matlgroupstring + convert(char(20),@material) end
            	when 3 then case when @seqcategory is null then convert(char(10),@spaces)
                    	else convert(char(10),@seqcategory) end + 
					case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end +
                 	case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end
            	when 4 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  +
                 	case when @seqcategory is null then convert(char(10),@spaces)
                    	else convert(char(10),@seqcategory) end + 
					case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end
            	when 5 then case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end  + 
					case when @poitem is null then convert(char(5),@spaces) 
						else @poitemstring end +
         			case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  +
                	case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end
          		when 6 then case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end + 
					case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  +
                 	case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  + 
					case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end
          		when 7 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  +
                  	case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end + 
					case when @poitem is null then convert(char(5),@spaces) 
						else @poitemstring end +
                	case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end
              	when 8 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end +
            		case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end + 
					case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end
			end
		end
   
   	if @source = 'SL'
       	begin
       	if @seqsummaryopt in (5,99) select @vendor = null, @vendorgroup = null
       	if @seqsummaryopt in (4,5,99) select @apref = null
       	if @seqsummaryopt in (3,99) select @sl = null, @slitem = null
   
		select @detailkey = 'APSLLine' +
           	case @seqsortlevel
               	when 1 then case when @sl is null then convert(char(30),@spaces)
   						else convert(char(30),@sl) end + 
   					case when @slitem is null then convert(char(5),@spaces)
						else @slitemstring end +
					case when @vendor is null then convert(char(9),@spaces)
						else @vendorgroupstring + @vendorstring end  + 
   					case when @apref is null then convert(char(15),@spaces)
						else convert(char(15),@apref) end
               	when 2 then case when @sl is null then convert(char(30),@spaces)
   						else convert(char(30),@sl) end + 
   					case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  +
                 	case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end
             	when 3 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end + 
   					case when @apref is null then convert(char(15),@spaces)
						else convert(char(15),@apref) end  +
					case when @sl is null then convert(char(30),@spaces)
   						else convert(char(30),@sl) end + 
   					case when @slitem is null then convert(char(5),@spaces) 
   						else @slitemstring end
          		when 4 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end + 
   					case when @apref is null then convert(char(15),@spaces)
						else convert(char(15),@apref) end  +
           			case when @sl is null then convert(char(30),@spaces)
   						else convert(char(30),@sl) end
           	end
		end
   
   	if @source = 'AP'
       	begin
		if @seqsummaryopt in (9,99) select @vendor = null, @vendorgroup = null
       	if @seqsummaryopt in (4,5,8,9,99) select @apref = null
       	if @seqsummaryopt in (2,3,4,5,99) select @po = null, @poitem = null
   
     	select @detailkey = 'APExpLine' +
        	case @seqsortlevel
				when 1 then case when @vendor is null then convert(char(9),@spaces) 
						else @vendorgroupstring + @vendorstring end +
					case when @apref is null then convert(char(15),@spaces) 
						else convert(char(15),@apref) end
            	when 2 then case when @po is null then convert(char(15),@spaces) 
						else convert(char(10),@po) + @poitemstring end +
					case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end
           		when 3 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end
				when 4 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end +
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end
				when 5 then case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end  + 
					case when @poitem is null then convert(char(5),@spaces)
                    	else @poitemstring end +
         			case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  +
              		case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end
           		when 6 then case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end  +
         			case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  +
                 	case when @material is null then convert(char(23),@spaces)
                    	else @matlgroupstring + convert(char(20),@material) end
           		when 7 then case when @vendor is null then convert(char(9),@spaces)
                    	else @vendorgroupstring + @vendorstring end  + 
					case when @apref is null then convert(char(15),@spaces)
                    	else convert(char(15),@apref) end  +
                 	case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end + 
					case when @poitem is null then convert(char(5),@spaces)
                    	else @poitemstring end
				when 8 then case when @po is null then convert(char(10),@spaces)
                    	else convert(char(10),@po) end + 
					case when @poitem is null then convert(char(5),@spaces)
                    	else @poitemstring end
         	end
    	end
   
   	if @source = 'IN' or (@source = 'MS' and @ctcategory <> 'E')
       	begin
   		if @seqsummaryopt in (2,3,4,5,6,99) select @MSticket = null
   		if @seqsummaryopt in (3,99) select @material = null, @matlgroup = null
   		if @seqsummaryopt in (4,5,6,99) select @loc = null
   
       	select @detailkey = 'MatlLine' +
           	case @seqsortlevel
               	when 1 then case when @material is null then convert(char(23),@spaces)
						else @matlgroupstring + convert(char(20),@material) end +
   					case when @loc is null then convert(char(10),@spaces) 
   						else convert(char(10),@loc) end
				when 2 then case when @loc is null then convert(char(10),@spaces)
   						else convert(char(10),@loc) end + 
   					case when @material is null then convert(char(23),@spaces)
						else @matlgroupstring + convert(char(20),@material) end
				when 3 then case when @seqcategory is null then convert(char(10),@spaces)
						else convert(char(10),@seqcategory) end + 
   					case when @material is null then convert(char(23),@spaces)
						else @matlgroupstring + convert(char(20),@material) end +
					case when @loc is null then convert(char(10),@spaces)
   						else convert(char(10),@loc) end
        		when 4 then case when @loc is null then convert(char(10),@spaces)
   						else convert(char(10),@loc) end + 
   					case when @seqcategory is null then convert(char(10),@spaces)
						else convert(char(10),@seqcategory) end +
					case when @material is null then convert(char(23),@spaces)
						else @matlgroupstring + convert(char(20),@material) end
			end
       	end
   	end
   
select @detailkey = isnull(@detailkey,'') + case when @seqsummaryopt <> 99 then @transctstring
   	else convert(char(10),@spaces) end
   
select @detailkey = isnull(@detailkey,'') +
    case @seqsummaryopt when 1 then 
	case when @jcmth is null then convert(char(8),@spaces)
		else convert(char(8),@jcmth,112) end -- 'yyyymmdd'
	else convert(char(8),@spaces) end
   
select @detailkey = isnull(@detailkey,'') +
    case @seqsummaryopt when 1 then 
	case when @jctransstring is null then convert(char(12),@spaces)
		else @jctransstring end
	else convert(char(12),@spaces) end
   
if @seqsummaryopt <> 1
   	begin
   	select /*@actualdate = null,*/ @jccddesc = null/*, @postdate = null*/
   	end

if @summarizebyrate = 'Y' and @source = 'PR' and @ctcategory <> 'E' 
	begin
	select @seqsummaryopt = @seqsummaryopt + 100
	end
  
bspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMGetDetailKey] TO [public]
GO
