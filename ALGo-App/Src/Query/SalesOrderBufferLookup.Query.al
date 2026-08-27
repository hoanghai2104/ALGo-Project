query 50100 "Sales Order Buffer Lookup"
{
    DataAccessIntent = ReadOnly;
    QueryType = Normal;

    elements
    {
        dataitem(SalesHeader; "Sales Header")
        {
            DataItemTableFilter = "Document Type" = const(Order);

            column(No; "No.")
            {
            }
            column(CustomerNo; "Sell-to Customer No.")
            {
            }
            column(TechnicianName; "Nom du technicien")
            {
            }
            column(TenantName; "Ship-to Name")
            {
            }

            dataitem(Customer; Customer)
            {
                SqlJoinType = LeftOuterJoin;
                DataItemLink = "No." = SalesHeader."Sell-to Customer No.";

                column(CustomerName; "Search Name")
                {
                }

                dataitem(SalesLine; "Sales Line")
                {
                    DataItemLink = "Document Type" = SalesHeader."Document Type",
                                   "Document No." = SalesHeader."No.";

                    DataItemTableFilter = Type = const(Item);

                    column(ItemNo; "No.")
                    {
                    }

                    dataitem(RelatedServiceHeader; "Service Header")
                    {
                        SqlJoinType = LeftOuterJoin;
                        DataItemLink = "Sales Order Reference" = SalesHeader."No.",
                                       "Document Type" = SalesHeader."Document Type";

                        column(InterventionNo; "No.")
                        {
                        }
                    }
                }
            }
        }
    }
}