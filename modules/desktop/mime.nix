{ ... }: {
  # System defaults in /etc/xdg/mimeapps.list. This does not rewrite
  # ~/.config/mimeapps.list, so existing scheme handlers stay.
  # LibreOffice is installed and removed from these types so package order
  # cannot make it the default. WPS keeps office documents; Okular keeps PDF;
  # Gwenview keeps images; Kate keeps plain text and Markdown.
  xdg.mime.defaultApplications = {
    "application/msword" = "wps-office-wps.desktop";
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
      "wps-office-wps.desktop";
    "application/rtf" = "wps-office-wps.desktop";
    "application/vnd.oasis.opendocument.text" = "wps-office-wps.desktop";
    "application/vnd.ms-excel" = "wps-office-et.desktop";
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "wps-office-et.desktop";
    "application/vnd.oasis.opendocument.spreadsheet" = "wps-office-et.desktop";
    "text/csv" = "wps-office-et.desktop";
    "application/vnd.ms-powerpoint" = "wps-office-wpp.desktop";
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
      "wps-office-wpp.desktop";
    "application/pdf" = "okularApplication_pdf.desktop";
    "image/png" = "org.kde.gwenview.desktop";
    "image/jpeg" = "org.kde.gwenview.desktop";
    "image/gif" = "org.kde.gwenview.desktop";
    "image/webp" = "org.kde.gwenview.desktop";
    "image/svg+xml" = "org.kde.gwenview.desktop";
    "text/plain" = "org.kde.kate.desktop";
    "text/markdown" = "org.kde.kate.desktop";
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };
  xdg.mime.removedAssociations = {
    "application/msword" = [ "libreoffice-writer.desktop" ];
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
      "libreoffice-writer.desktop"
    ];
    "application/rtf" = [ "libreoffice-writer.desktop" ];
    "application/vnd.oasis.opendocument.text" = [ "libreoffice-writer.desktop" ];
    "application/vnd.ms-excel" = [ "libreoffice-calc.desktop" ];
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
      "libreoffice-calc.desktop"
    ];
    "application/vnd.oasis.opendocument.spreadsheet" = [ "libreoffice-calc.desktop" ];
    "text/csv" = [ "libreoffice-calc.desktop" ];
    "application/vnd.ms-powerpoint" = [ "libreoffice-impress.desktop" ];
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
      "libreoffice-impress.desktop"
    ];
    "application/pdf" = [ "libreoffice-draw.desktop" ];
    "image/png" = [ "libreoffice-draw.desktop" ];
    "image/jpeg" = [ "libreoffice-draw.desktop" ];
    "image/gif" = [ "libreoffice-draw.desktop" ];
    "image/webp" = [ "libreoffice-draw.desktop" ];
    "image/svg+xml" = [ "libreoffice-draw.desktop" ];
  };

}
