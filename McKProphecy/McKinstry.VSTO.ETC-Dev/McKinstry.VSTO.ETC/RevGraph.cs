using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;

namespace McKinstry.ETC.Template
{
    [Serializable(), ClassInterface(ClassInterfaceType.AutoDual), ComVisible(true)]
    class RevGraph: StandardOleMarshalObject
    {
        public void AddRevenueGraph(ListObject PRGPivot, Range RevHeaders, Range RevEnd, byte RevdataEntryAreaOffset)
        {
            Range RevStart = null;
            Worksheet _ws = PRGPivot.Parent;
            try
            {
                dynamic startDraw = _ws.UsedRange.Height + 15;
                int endCol = RevHeaders.Columns.Count;
                var charts = _ws.ChartObjects() as ChartObjects;
                var chartObj = charts.Add(0, startDraw, (.55 * endCol) * 100, 255) as ChartObject;
                var myChart = chartObj.Chart;

                chartObj.Activate();

                myChart.ChartType = XlChartType.xlLine;
                SeriesCollection seriesCollection = myChart.SeriesCollection();
                Range endCell = null;
                Range startCell = null;

                int startCol = PRGPivot.ListColumns["Current Month Catch Up"].Index + RevdataEntryAreaOffset;
                int PRGcol = PRGPivot.ListColumns["PRG"].Index;
                RevStart = _ws.Cells[RevHeaders.Row, startCol];

                for (int i = 1; i <= PRGPivot.ListRows.Count; i++)
                {
                    int row = RevHeaders.Row + i;
                    Series series = seriesCollection.NewSeries();
                    series.Name = _ws.Cells[row, PRGcol].Formula;
                    series.XValues = _ws.get_Range(RevStart, RevEnd);

                    startCell = _ws.Cells[row, startCol];
                    endCell = _ws.Cells[row, endCol];

                    series.Values = _ws.get_Range(startCell, endCell);
                    series.ChartType = XlChartType.xlLine;
                }
            }
            catch (Exception) { throw; }
            finally
            {
                if (RevStart != null) Marshal.ReleaseComObject(RevStart);
            }
        }
    }

}
