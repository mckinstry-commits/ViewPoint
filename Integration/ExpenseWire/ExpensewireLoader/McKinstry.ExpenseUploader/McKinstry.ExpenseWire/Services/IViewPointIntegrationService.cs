using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using McKinstry.ExpenseWire.Model;

namespace McKinstry.ExpenseWire.Services
{
    public interface IViewPointIntegrationService
    {
        void AddHeader(ExpenseWireSendDataTransactionExpenseSearchExpense expense);
        void AddDetail(ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetail detail);
        void AddTimeSheet();
    }
}
