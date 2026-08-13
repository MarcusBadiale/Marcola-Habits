import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// O que o `ShareLink` entrega.
///
/// `DataRepresentation` e não `FileRepresentation`: nada é escrito em disco, então não há temp
/// dir pra limpar nem arquivo órfão pra vazar. Quem materializa o arquivo é o destino escolhido
/// no share sheet.
struct HabitExportDocument: Transferable, Hashable {

    static let fileName = "marcola-export.json"

    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { document in
            document.data
        }
        .suggestedFileName(fileName)
    }
}
