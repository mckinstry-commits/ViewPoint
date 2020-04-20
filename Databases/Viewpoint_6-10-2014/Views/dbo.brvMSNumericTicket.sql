SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[brvMSNumericTicket] as

/*==================================================================================      

Author:
unknown

Create date:   
unknown

Usage:
Drives the MS Missing Ticket report

Things to keep in mind regarding this report and proc: 

So there are a few things here that need to be clarified regarding MS Tickets

	1 - MS Tickets are natively a varchar(10) datatype having values with no defined mask
	2 - While customers can add in non-numeric values, the typical usage of the Ticket 
		field (as of writing this) is to have it contain purely numeric values with
		maybe a letter in the last position indicating this the ticket is a correction
		of some sort.
		
The key point here is that there is no defined mask, so essentially the ticket field is a 
freeform alphanumeric field. Attempting to find out all the possible combinations this 
field can contain, order those value correctly, figure out the gaps, AND do it all in a 
way that would perform quickly is not currently possible without a field mask. Take, for
instance, the following scenario:

	Row 1 - Ticket = '5.0001'
	Row 2 - Ticket = '5.01'
	
Is there a gap between these two values? The answer could be yes, with one of three possible
scenarios, or a single scenario no. Lets start with the easiest one first, no:

	there is no gap because as a user of the software tickets ending in .01 and .0001 are 
	special cases for us and there will never be a .00, .0000, .02, .0002 or any other decimal
	number but those two.
	
the yes scenarios:

	1 - the gap is 5.0002 to 5.0099
	2 - the gap is 5.0002 to 5.009
	3 - the gap is just the value 5
		this one is a bit tough to get, but 5.01 - .01 = 5, and 5.0001 + .0001 = 5.0002
		so the order would have to change since 5.0002 is no longer between 5.0001 and 5

that last one is a bit of stretch, but serves to the prove the point that without a mask
there is no way to know how the values increment. And all of this is just using numbers, what
happens with we toss alpha characters into the mix? What is the valid gap between 1234A and 1234AA?

So the core of the problem comes back to the fact that without a field mask there is no safe
and reliable way to figure out when and how to increment values. 

Because of the complexity of the above scenarios, the following code simplifies things by 
narrowing the type of data we are looking at. The code will ONLY bring back numeric values
(the case statement). We cannot rely on the ISNumeric funtion as it could freak out on 
comma and dash characters. Please read up on the limitations on the ISNumeric functions if 
have any questions regarding that last statement. So we have to look for numeric patterns instead.
We include the check for numeric values with decimals because if we had a range of tickets from
123 to 130.01 with no ticket 130, then the report would skip the 130 value all together.

Finally, the floor function is really just a truncate for numbers. 5.999 is still 5, no need to round
up to 6.

Related reports:     

Revision History      
Date		Author			Issue						Description
04/15/11	DanK	C-143359/V1-D-01619		Altered Round() to truncate and not necessarily round up
		Added Pattern search to cope with Float values which are numeric but can't be properly cast.
01/10/13	ScottA	C-143359/V1-D-06391 & D-06392	The usage of rounding and some of the code
		that was added previously was not working properly. Introduced the use of PatIndex in the
		where statement and added floor function to replace rounding. Added the Ticket field (previosly
		it was just modified value of Ticket as MSTicket) to see what the value is before it is 
		modified by the floor function. Also added the notes above.

==================================================================================*/  

with cte_DistinctTicket
as 
(
	SELECT DISTINCT
		MSCo
		, case when
				PATINDEX('%[^0-9.]%', ltrim(rtrim(Ticket))) = 0
				and charindex('.',Ticket, charindex('.',Ticket) + 1) = 0 
				and (charindex('.', Ticket) = 0 or charindex('.',Ticket) between 2 and len(Ticket) - 1)
				and Ticket is not null
			then Ticket
			else null
		  end as Ticket
		, FromLoc
	FROM		
		MSTD
)

select 
	d.MSCo
	, h.Name as CoName
	, d.Ticket
	, cast(floor(d.Ticket) as bigint) as MSTicket
	, d.FromLoc
	, l.Description as LocDesc
FROM
	cte_DistinctTicket d
JOIN		
	HQCO h on
		d.MSCo = h.HQCo 
JOIN		
	INLM l on 
		d.MSCo = l.INCo 
		and d.FromLoc = l.Loc

GO
GRANT SELECT ON  [dbo].[brvMSNumericTicket] TO [public]
GRANT INSERT ON  [dbo].[brvMSNumericTicket] TO [public]
GRANT DELETE ON  [dbo].[brvMSNumericTicket] TO [public]
GRANT UPDATE ON  [dbo].[brvMSNumericTicket] TO [public]
GRANT SELECT ON  [dbo].[brvMSNumericTicket] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvMSNumericTicket] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvMSNumericTicket] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvMSNumericTicket] TO [Viewpoint]
GO
