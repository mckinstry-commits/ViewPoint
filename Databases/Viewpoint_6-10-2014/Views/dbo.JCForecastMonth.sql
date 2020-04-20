SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCForecastMonth] as select a.* From vJCForecastMonth a
GO
GRANT SELECT ON  [dbo].[JCForecastMonth] TO [public]
GRANT INSERT ON  [dbo].[JCForecastMonth] TO [public]
GRANT DELETE ON  [dbo].[JCForecastMonth] TO [public]
GRANT UPDATE ON  [dbo].[JCForecastMonth] TO [public]
GRANT SELECT ON  [dbo].[JCForecastMonth] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCForecastMonth] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCForecastMonth] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCForecastMonth] TO [Viewpoint]
GO
