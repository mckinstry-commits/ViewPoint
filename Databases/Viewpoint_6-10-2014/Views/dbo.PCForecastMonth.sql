SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCForecastMonth] as select a.* From vPCForecastMonth a
GO
GRANT SELECT ON  [dbo].[PCForecastMonth] TO [public]
GRANT INSERT ON  [dbo].[PCForecastMonth] TO [public]
GRANT DELETE ON  [dbo].[PCForecastMonth] TO [public]
GRANT UPDATE ON  [dbo].[PCForecastMonth] TO [public]
GRANT SELECT ON  [dbo].[PCForecastMonth] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCForecastMonth] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCForecastMonth] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCForecastMonth] TO [Viewpoint]
GO
