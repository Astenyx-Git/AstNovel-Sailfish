Type = harbour
Name = AstNovel
Version = 1.0.0
Summary = A novel management application for Sailfish OS
Description = NovelSpace helps writers organize their stories with book management, chapter editing, character tracking, and world building features.
License = BSD-3-Clause
Vendor = Astenyx
Icon = harbour-astn
Homepage = https://github.com/astenyx/astn-sailfish

# Dependencies
Requires = sailfishsilica-qt5 >= 1.0.0
# Optional: add other dependencies here

# Build dependencies
RequiresBuild = qt5-qtdeclarative-devel >= 5.15.0

# Build instructions
[Build]
# Add build commands here
# Example: make %{?jobs:-j%{jobs}}

# Install instructions
[Install]
# Add install commands here
# Example: make install DESTDIR=%{buildroot}

# Files to include
[Files]
app = app
harbour = harbour

# Extra files
[ExtraFiles]
# Add extra files here

# RPM specific
[Rpm]
# Add RPM specific configuration here

# Debian specific
[Debian]
# Add Debian specific configuration here

# Distribution specific
[Distributions]
# Add distribution specific configuration here
