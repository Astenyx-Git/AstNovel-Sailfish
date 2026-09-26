Name:       harbour-astnovel
Summary:    AstNovel - novel writing and worldbuilding
Version:    4.50.Ast.3
Release:    1
License:    Proprietary
Group:      Applications/Productivity
URL:        https://github.com/Astenyx-Git/AstNovel-Sailfish
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 1.0
BuildRequires: pkgconfig(sailfishapp) >= 1.0.2
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Gui)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(openssl)

%description
AstNovel is a novel management application: books, chapters,
characters and world setting entries, with Apple-style visuals
adapted to Sailfish Silica.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5

%install
rm -rf %{buildroot}
%qmake5_install

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
