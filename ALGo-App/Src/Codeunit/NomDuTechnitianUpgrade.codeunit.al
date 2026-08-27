codeunit 50117 NomDuTechnitianUpgrade
{
    subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeSalesHeader();
        UpgradeServiceHeader();
    end;

    local procedure UpgradeSalesHeader()
    var
        salesHeader: Record "Sales Header";
    begin
        salesHeader.Reset();
        salesHeader.LoadFields(
            "No.",
            "Document Type",
            "Nom du technicien",
            TechnitianName
        );
        if salesHeader.FindSet(true) then
            repeat
                if (salesHeader.TechnitianName <> '') and (salesHeader."Nom du technicien" = '') then begin
                    salesHeader."Nom du technicien" := salesHeader.TechnitianName;
                    if salesHeader.Modify() then;
                end;
            until salesHeader.Next() = 0;
    end;

    local procedure UpgradeServiceHeader()
    var
        serviceHeader: Record "Service Header";
    begin
        serviceHeader.Reset();
        serviceHeader.LoadFields(
            "No.",
            "Document Type",
            "Nom du technicien",
            TechnitianName
        );
        if serviceHeader.FindSet(true) then
            repeat
                if (serviceHeader.TechnitianName <> '') and (serviceHeader."Nom du technicien" = '') then begin
                    serviceHeader."Nom du technicien" := serviceHeader.TechnitianName;
                    if serviceHeader.Modify() then;
                end;
            until serviceHeader.Next() = 0;
    end;

}