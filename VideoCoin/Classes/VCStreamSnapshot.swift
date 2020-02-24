//
// Created by Ryoichiro Oka on 12/15/19.
// Copyright (c) 2019 Ryoichiro Oka. All rights reserved.
//

import Foundation

//TODO complete impl
public struct VCStreamSnapshot: Decodable {
	public let id: String
	public let name: String
	public let input_url: URL
	public let output_url: URL
	public let status: VCStreamStatus
	public let rtmp_url: URL
}

/*
 "id": "3e311a9a-99b4-4694-696e-d906c89540fa",
 "name": "stream_from_api",
 "input_url": "http://rtmp.studio.snb.videocoin.network/hls/3e311a9a-99b4-4694-696e-d906c89540fa/index.m3u8",
 "output_url": "https://streams-snb.videocoin.network/3e311a9a-99b4-4694-696e-d906c89540fa/index.m3u8",
 "stream_contract_id": "6382895374400863069",
 "stream_contract_address": "",
 "status": "STREAM_STATUS_NEW",
 "input_status": "INPUT_STATUS_NONE",
 "created_at": "2019-10-19T00:39:50.900265970Z",
 "updated_at": "2019-10-19T00:39:50.900338472Z",
 "ready_at": null,
 "completed_at": null,
 "rtmp_url": "rtmp://rtmp.studio.snb.videocoin.network:1935/live/3e311a9a-99b4-4694-696e-d906c89540fa"
*/
