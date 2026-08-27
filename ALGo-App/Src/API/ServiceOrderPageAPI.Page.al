page 50108 ServiceOrderPageAPI
{
    PageType = API;
    Caption = 'Service Order API';
#pragma warning disable AA0101
    APIPublisher = 'ELCA';
#pragma warning restore AA0101
    APIGroup = 'elca';
    APIVersion = 'v2.0';
    EntityName = 'serviceorder';
    EntitySetName = 'serviceorders';
    SourceTable = "Service Header";
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
                field("serviceOrderNo"; Rec."No.")
                {
                }
                field("documentType"; Rec."Document Type") { }
                field("customerNo"; Rec."Customer No.")
                {
                }
                field("shipToCode"; Rec."Ship-to Code") { }
                field("nomDuTechnicien"; Rec."Nom du technicien") { }
            }
        }
    }
}