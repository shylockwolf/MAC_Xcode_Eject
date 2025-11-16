//
//  ContentView.swift
//  Eject
//
//  Created by Shylock Wolf on 2025/11/16.
//

import SwiftUI

struct ContentView: View {
    @State private var mountedVolumes: [String] = []
    @State private var externalVolumes: [String] = []
    @State private var isLoading = false
    @State private var ejectMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "externaldrive")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("外置存储设备自动弹出")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.top)
            
            // 统一显示区：加载状态、设备列表和操作日志（带实时滚屏功能）
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // 加载状态
                        if isLoading {
                            ProgressView("正在处理设备...")
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        // 所有外置挂载设备列表
                        if !externalVolumes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "externaldrive.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                    Text("所有外置挂载设备")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(externalVolumes, id: \.self) {
                                        Text($0)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // 已弹出的外置设备列表
                        if !externalVolumes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16))
                                    Text("已弹出的外置设备")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(externalVolumes, id: \.self) { volume in
                                        HStack(spacing: 8) {
                                            Image(systemName: "externaldrive.fill")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 14))
                                            Text(volume)
                                                .font(.system(.body, design: .monospaced))
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                    }
                                }
                                .background(Color.orange.opacity(0.05))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // 操作日志
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "terminal.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                Text("操作日志")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Text(ejectMessage)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .padding(10)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // 用于自动滚动的锚点
                        Text("")
                            .id("bottomAnchor")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .onChange(of: ejectMessage) { _ in
                    // 日志更新时自动滚动到底部
                    withAnimation {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            autoEjectProcess()
        }
    }
    
    func autoEjectProcess() {
        isLoading = true
        ejectMessage = "正在扫描设备...\n"
        
        DispatchQueue.global(qos: .background).async {
            // 扫描所有设备
            let result = self.executeShellCommand("mount")
            let volumes = result.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            let externalVols = volumes.filter { $0.contains("/Volumes/") && !$0.contains("/System/Volumes/") }
            
            DispatchQueue.main.async {
                self.mountedVolumes = volumes
                self.ejectMessage += "检测到 \(externalVols.count) 个外置挂载设备\n"
            }
            
            // 如果有外置设备，直接弹出
            if !externalVols.isEmpty {
                var message = "开始处理弹出操作...\n"
                DispatchQueue.main.async {
                    self.ejectMessage += message
                }
                
                var processResults = ""
                for volumeInfo in externalVols {
                    let device = self.extractDeviceName(from: volumeInfo)
                    let volume = self.extractVolumeName(from: volumeInfo)
                    
                    // 先卸载
                    message = "正在弹出：\(volume) (设备: \(device))..."
                    DispatchQueue.main.async {
                        self.ejectMessage += message
                    }
                    
                    let unmountResult = self.executeShellCommand("diskutil unmount \(device)")
                    
                    // 短暂延迟
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    // 再弹出
                    let ejectResult = self.executeShellCommand("diskutil eject \(device)")
                    
                    // 检查是否成功弹出
                    let checkResult = self.executeShellCommand("diskutil list \(device) 2>/dev/null | grep -q '\(device)' && echo 'still_mounted'")
                    
                    let status = checkResult.contains("still_mounted") ? "失败" : "成功"
                    let resultLine = " [\(status)]\n"
                    
                    processResults += "\(volume) (设备: \(device)) - \(status)\n"
                    
                    DispatchQueue.main.async {
                        self.ejectMessage += resultLine
                    }
                }
                
                // 弹出完成后重新扫描
                let finalResult = self.executeShellCommand("mount")
                let finalVolumes = finalResult.components(separatedBy: "\n").filter { !$0.isEmpty }
                let finalExternalVols = finalVolumes.filter { $0.contains("/Volumes/") && !$0.contains("/System/Volumes/") }
                
                let remainingDevices = externalVols.count - finalExternalVols.count
                let finalStatus = remainingDevices == externalVols.count ? "全部成功弹出" : "部分成功弹出"
                
                DispatchQueue.main.async {
                    self.mountedVolumes = finalVolumes
                    self.externalVolumes = finalExternalVols
                    self.isLoading = false
                    self.ejectMessage += "\n弹出操作完成：\(finalStatus)\n共处理 \(externalVols.count) 个外置设备，成功弹出 \(remainingDevices) 个"
                }
            } else {
                // 没有外置设备
                DispatchQueue.main.async {
                    self.externalVolumes = externalVols
                    self.isLoading = false
                    self.ejectMessage += "没有需要弹出的外置存储设备"
                }
            }
        }
    }
    
    func executeShellCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.standardInput = nil
        
        do {
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("执行命令失败: \(error)")
        }
        
        return ""
    }
    
    func extractDeviceName(from volumeInfo: String) -> String {
        // 从挂载信息中提取设备名，如 "/dev/disk4s1"
        if let range = volumeInfo.range(of: " on ") {
            return String(volumeInfo[..<range.lowerBound])
        }
        return ""
    }
    
    func extractVolumeName(from volumeInfo: String) -> String {
        // 从挂载信息中提取卷名，如 "Trae CN"
        if let onRange = volumeInfo.range(of: " on /Volumes/"),
           let optionsRange = volumeInfo.range(of: " (", options: .backwards, range: onRange.upperBound..<volumeInfo.endIndex) {
            
            let startIndex = volumeInfo.index(onRange.upperBound, offsetBy: 0)
            let endIndex = optionsRange.lowerBound
            return String(volumeInfo[startIndex..<endIndex])
        }
        return ""
    }
}

#Preview {
    ContentView()
}
