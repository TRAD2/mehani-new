enum HelpDeskStatus {
  open,
  closed,
}

class HelpDeskStatusModel {
  HelpDeskStatus status;
  String name;

  HelpDeskStatusModel({
    this.status = HelpDeskStatus.open,
    this.name = "",
  });
}