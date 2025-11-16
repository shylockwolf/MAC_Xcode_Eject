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
            
            if isLoading {
                ProgressView("正在处理设备...")
                    .padding()
            } else {
                // 所有挂载设备列表
                if !mountedVolumes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("所有挂载设备")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(mountedVolumes, id: \.self) { volume in
                                    Text(volume)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .frame(height: 100)
                        .padding(.vertical, 8)
                    }
                }
                
                // 外置存储设备列表
                if !externalVolumes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已弹出的外置设备")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(externalVolumes, id: \.self) { volume in
                                    HStack {
                                        Image(systemName: "externaldrive.fill")
                                            .foregroundColor(.orange)
                                        Text(volume)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                }
                            }
                        }
                        .frame(height: 80)
                        .padding(.vertical, 8)
                    }
                }
            }
            
            if !ejectMessage.isEmpty {
                ScrollView {
                    Text(ejectMessage)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(maxHeight: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
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
                self.ejectMessage = "找到 \(volumes.count) 个挂载设备，其中 \(externalVols.count) 个外置设备\n"
            }
            
            // 如果有外置设备，直接弹出
            if !externalVols.isEmpty {
                DispatchQueue.main.async {
                    self.ejectMessage += "开始自动弹出所有外置设备...\n"
                }
                
                var message = ""
                for volumeInfo in externalVols {
                    let device = self.extractDeviceName(from: volumeInfo)
                    let volume = self.extractVolumeName(from: volumeInfo)
                    
                    // 先卸载
                    let unmountResult = self.executeShellCommand("diskutil unmount \(device)")
                    
                    // 短暂延迟
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    // 再弹出
                    let ejectResult = self.executeShellCommand("diskutil eject \(device)")
                    
                    // 检查是否成功弹出
                    let checkResult = self.executeShellCommand("diskutil list \(device) 2>/dev/null | grep -q '\(device)' && echo 'still_mounted'")
                    
                    let status = checkResult.contains("still_mounted") ? "警告: 可能未完全弹出" : "成功"
                    
                    message += "  Volume \(volume) on \(device) unmounted + Disk \(device) ejected - \(status)\n"
                    
                    DispatchQueue.main.async {
                        self.ejectMessage = "找到 \(volumes.count) 个挂载设备，其中 \(externalVols.count) 个外置设备\n开始自动弹出所有外置设备...\n" + message
                    }
                }
                
                // 弹出完成后重新扫描
                let finalResult = self.executeShellCommand("mount")
                let finalVolumes = finalResult.components(separatedBy: "\n").filter { !$0.isEmpty }
                let finalExternalVols = finalVolumes.filter { $0.contains("/Volumes/") && !$0.contains("/System/Volumes/") }
                
                DispatchQueue.main.async {
                    self.mountedVolumes = finalVolumes
                    self.externalVolumes = finalExternalVols
                    self.isLoading = false
                    self.ejectMessage = "找到 \(volumes.count) 个挂载设备，其中 \(externalVols.count) 个外置设备\n开始自动弹出所有外置设备...\n" + message + "\n弹出操作完成！"
                }
            } else {
                // 没有外置设备
                DispatchQueue.main.async {
                    self.externalVolumes = externalVols
                    self.isLoading = false
                    self.ejectMessage = "找到 \(volumes.count) 个挂载设备，未发现外置存储设备"
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
