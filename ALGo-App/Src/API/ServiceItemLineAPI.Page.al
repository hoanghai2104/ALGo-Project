page 50110 ServiceItemLineAPI
{
    PageType = API;
    Caption = 'Service Item Line API';
#pragma warning disable AA0101
    APIPublisher = 'ELCA';
#pragma warning restore AA0101
    APIGroup = 'elca';
    APIVersion = 'v2.0';
    EntityName = 'serviceitemline';
    EntitySetName = 'serviceitemlines';
    SourceTable = "Service Item Line";
    DelayedInsert = true;
    SourceTableView = where("Document Type" = const(Order), "Coupled to FS" = const(True));
    ODataKeyFields = SystemId;
    ChangeTrackingAllowed = true;
    layout
    {
        area(Content)
        {
            repeater(serviceorder)
            {
                field(systemId; Rec.SystemId) { }
                field("serviceItemLineNo"; Rec."Line No.")
                {
                }
                field("shipToCode"; Rec."Ship-to Code") { }
            }
        }
    }
}