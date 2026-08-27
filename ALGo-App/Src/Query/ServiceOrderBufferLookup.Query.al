query 50101 "Service Order Buffer Lookup"
{
    DataAccessIntent = ReadOnly;
    QueryType = Normal;

    elements
    {
        dataitem(ServiceHeader; "Service Header")
        {
            DataItemTableFilter = "Document Type" = const(Order);
            column(No; "No.")
            {
            }
            column(CustomerNo; "Customer No.")
            {
            }
            column(TechnicianName; "Nom du technicien")
            {
            }
            column(InterventionNo; "N° de l’intervention")
            {
            }
            column(TenantName; "Ship-to Name")
            {
            }

            dataitem(Customer; Customer)
            {
                SqlJoinType = LeftOuterJoin;
                DataItemLink = "No." = ServiceHeader."Customer No.";

                column(CustomerName; "Search Name")
                {
                }

                dataitem(ServiceLine; "Service Line")
                {
                    DataItemLink = "Document Type" = ServiceHeader."Document Type",
                                   "Document No." = ServiceHeader."No.";

                    DataItemTableFilter = Type = const(Item);

                    column(ItemNo; "No.")
                    {
                    }
                }
            }
        }
    }
}