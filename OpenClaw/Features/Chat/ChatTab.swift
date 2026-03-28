import SwiftUI

struct ChatTab: View {
    @State private var vm: ChatViewModel

    init(client: GatewayClientProtocol) {
        _vm = State(initialValue: ChatViewModel(client: client))
    }

    var body: some View {
        ChatView(vm: vm)
    }
}
