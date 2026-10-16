import SwiftUI

struct ContentView: View {
    @ObservedObject var store: DiskStore
    /// Falso solo para las capturas: ImageRenderer no pinta el contenido de un ScrollView.
    var scrollable = true

    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 0) {
                TitleBar()
                maybeScroll {
                    VStack(alignment: .leading, spacing: 22) {
                        Header()
                        if !store.toolsReady { SetupCard() }
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel("Discos conectados")
                            if store.disks.isEmpty {
                                EmptyCard()
                            } else {
                                ForEach(store.disks) { item in
                                    DiskCard(item: item, store: store)
                                }
                            }
                        }
                        TipCard()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                if !scrollable { Spacer(minLength: 0) }
                FooterBar(store: store)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .background(WindowConfigurator())
        .preferredColorScheme(.dark)
        .frame(minWidth: 700, idealWidth: 780, minHeight: 540, idealHeight: 620)
    }
}

extension ContentView {
    @ViewBuilder fileprivate func maybeScroll<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if scrollable { ScrollView { content() } } else { content() }
    }
}

private struct TitleBar: View {
    var body: some View {
        HStack(spacing: 10) {
            PixelLogo(height: 20)
            Text("PoxiNTFS")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.text)
            Text("beta")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.07)))
            Spacer()
        }
        .padding(.leading, 84)
        .padding(.trailing, 20)
        .frame(height: 38)
    }
}

private struct Header: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Discos NTFS")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(Theme.text)
            Text("Copia, borra y edita archivos en discos de Windows desde tu Mac. Gratis y sin anuncios.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
        }
    }
}

private struct DiskCard: View {
    let item: DiskItem
    @ObservedObject var store: DiskStore

    private var isBusy: Bool { store.busy.contains(item.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Theme.accent)
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.volume.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(item.volume.device)
                }

                Spacer(minLength: 12)

                if isBusy {
                    ProgressView().controlSize(.small).padding(.trailing, 6)
                } else {
                    statusPill.fixedSize()
                    actions.fixedSize()
                }
            }

            if let error = store.errors[item.id] {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.red)
                    Text(error).foregroundStyle(Theme.text.opacity(0.9))
                }
                .font(.system(size: 12))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.red.opacity(0.1)))
            }
        }
        .card()
    }

    private var subtitle: String {
        let size = ByteCountFormatter.string(fromByteCount: item.volume.size, countStyle: .file)
        let media = item.volume.media.isEmpty ? "" : " · \(item.volume.media)"
        return "NTFS · \(size)\(media)"
    }

    @ViewBuilder private var statusPill: some View {
        switch item.state {
        case .writable: Pill(text: "Lectura y escritura", color: Theme.green)
        case .readOnly: Pill(text: "Solo lectura", color: Theme.info)
        case .unmounted: Pill(text: "Sin montar", color: Theme.muted)
        }
    }

    @ViewBuilder private var actions: some View {
        switch item.state {
        case .writable:
            Button("Abrir") { store.open(item) }.buttonStyle(GhostButtonStyle())
            Button("Expulsar") { store.eject(item) }.buttonStyle(GhostButtonStyle())
        case .readOnly, .unmounted:
            Button("Activar escritura") { store.enableWrite(item) }.buttonStyle(PrimaryButtonStyle())
            Button("Expulsar") { store.eject(item) }.buttonStyle(GhostButtonStyle())
        }
    }
}

private struct EmptyCard: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.accent)
                Image(systemName: "externaldrive.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 44, height: 44)
            Text("Conecta un disco NTFS")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.text)
            Text("Aparecerá aquí solo. Funciona con pendrives, discos duros y SSD externos formateados en Windows.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.02)))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.14), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
        )
    }
}

private struct SetupCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.warn)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.warn.opacity(0.13)))
            VStack(alignment: .leading, spacing: 4) {
                Text("Falta un componente")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text("Para escribir en NTFS hace falta FUSE-T y el driver ntfs-3g. Instala FUSE-T con Homebrew:")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                Text("brew install --cask fuse-t")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.3)))
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private struct TipCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(Theme.yellow)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.yellow.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Antes de desconectar, expulsa")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text("Quitar el disco sin expulsarlo puede dañar los archivos. Usa siempre el botón Expulsar.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private struct FooterBar: View {
    @ObservedObject var store: DiskStore

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(store.busy.isEmpty ? Theme.green : Theme.warn)
                .frame(width: 7, height: 7)
            Text(store.statusText)
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
            Spacer()
            Text("ntfs-3g · FUSE-T")
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted.opacity(0.7))
        }
        .padding(.horizontal, 28)
        .frame(height: 34)
        .background(Color.black.opacity(0.18))
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1) }
    }
}
